# frozen_string_literal: true

# Add helper to Proxy commands for Quadlet image resolution
Kamal::Commands::Proxy.class_eval do
  def quadlet_image
    if proxy_run_config
      image = proxy_run_config.image
      # Ensure docker.io prefix for Podman (Podman requires explicit registry)
      image.include?(".") ? image : "docker.io/#{image}"
    else
      "docker.io/basecamp/kamal-proxy:#{Kamal::Configuration::Proxy::Run::MINIMUM_VERSION}"
    end
  end

  def quadlet_run_command
    proxy_run_config&.run_command
  end
end

Kamal::Cli::Proxy.class_eval do
  no_commands do
    alias_method :original_boot, :boot
    alias_method :original_reboot, :reboot
    alias_method :original_start, :start
    alias_method :original_stop, :stop
    alias_method :original_remove_container, :remove_container
  end

  def boot
    return original_boot unless KAMAL.quadlet_enabled?

    with_lock do
      on(KAMAL.hosts) do |host|
        execute *KAMAL.docker.create_network
      rescue SSHKit::Command::Failed => e
        raise unless e.message.include?("already exists")
      end

      on(KAMAL.proxy_hosts) do |host|
        execute *KAMAL.registry.login

        version = capture_with_info(*KAMAL.proxy(host).version).strip.presence

        if version && Kamal::Utils.older_version?(version, Kamal::Configuration::Proxy::Run::MINIMUM_VERSION)
          raise "kamal-proxy version #{version} is too old, run `kamal proxy reboot` in order to update to at least #{Kamal::Configuration::Proxy::Run::MINIMUM_VERSION}"
        end

        execute *KAMAL.proxy(host).ensure_apps_config_directory

        # Write Quadlet .container file and start via systemd
        proxy = KAMAL.proxy(host)
        run_cmd = proxy.run
        unit_name = "kamal-proxy"
        image = proxy.quadlet_image

        # Pull the proxy image (Quadlet uses Pull=never)
        execute :podman, :pull, image, raise_on_non_zero_exit: false

        content = KAMAL.quadlet.container_file_content(
          unit_name: unit_name,
          image: image,
          run_args: run_cmd[2..],
          cmd: proxy.quadlet_run_command,
          restart_policy: "on-failure"
        )

        execute *KAMAL.quadlet.ensure_quadlet_directory
        upload! StringIO.new(content), KAMAL.quadlet.quadlet_file_path(unit_name)
        execute *KAMAL.quadlet.daemon_reload
        execute *KAMAL.quadlet.start_unit(unit_name)
      end
    end
  end

  def reboot
    return original_reboot unless KAMAL.quadlet_enabled?

    confirming "This will cause a brief outage on each host. Are you sure?" do
      with_lock do
        host_groups = options[:rolling] ? KAMAL.proxy_hosts : [ KAMAL.proxy_hosts ]
        host_groups.each do |hosts|
          host_list = Array(hosts).join(",")
          run_hook "pre-proxy-reboot", hosts: host_list
          on(hosts) do |host|
            proxy = KAMAL.proxy(host)
            execute *KAMAL.auditor.record("Rebooted proxy"), verbosity: :debug
            execute *KAMAL.registry.login

            # Stop and remove old container
            execute *KAMAL.quadlet.stop_unit("kamal-proxy"), raise_on_non_zero_exit: false
            execute *proxy.remove_container
            execute *proxy.ensure_apps_config_directory

            # Write new Quadlet file and start
            run_cmd = proxy.run
            unit_name = "kamal-proxy"
            image = proxy.quadlet_image

            # Pull the proxy image (Quadlet uses Pull=never)
            execute :podman, :pull, image, raise_on_non_zero_exit: false

            content = KAMAL.quadlet.container_file_content(
              unit_name: unit_name,
              image: image,
              run_args: run_cmd[2..],
              restart_policy: "on-failure"
            )

            execute *KAMAL.quadlet.ensure_quadlet_directory
            upload! StringIO.new(content), KAMAL.quadlet.quadlet_file_path(unit_name)
            execute *KAMAL.quadlet.daemon_reload
            execute *KAMAL.quadlet.start_unit(unit_name)
          end
          run_hook "post-proxy-reboot", hosts: host_list
        end
      end
    end
  end

  def start
    return original_start unless KAMAL.quadlet_enabled?

    with_lock do
      on(KAMAL.proxy_hosts) do |host|
        execute *KAMAL.auditor.record("Started proxy"), verbosity: :debug
        execute *KAMAL.quadlet.start_unit("kamal-proxy")
      end
    end
  end

  def stop
    return original_stop unless KAMAL.quadlet_enabled?

    with_lock do
      on(KAMAL.proxy_hosts) do |host|
        execute *KAMAL.auditor.record("Stopped proxy"), verbosity: :debug
        execute *KAMAL.quadlet.stop_unit("kamal-proxy"), raise_on_non_zero_exit: false
      end
    end
  end

  def remove_container
    return original_remove_container unless KAMAL.quadlet_enabled?

    with_lock do
      on(KAMAL.proxy_hosts) do
        execute *KAMAL.auditor.record("Removed proxy container"), verbosity: :debug
        execute *KAMAL.quadlet.stop_unit("kamal-proxy"), raise_on_non_zero_exit: false
        execute *KAMAL.quadlet.remove_quadlet_file("kamal-proxy")
        execute *KAMAL.quadlet.daemon_reload
        execute *KAMAL.proxy(host).remove_container
      end
    end
  end
end
