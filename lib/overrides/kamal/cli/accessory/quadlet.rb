# frozen_string_literal: true

Kamal::Cli::Accessory.class_eval do
  no_commands do
    alias_method :original_boot, :boot
    alias_method :original_start, :start
    alias_method :original_stop, :stop
    alias_method :original_remove_accessory, :remove_accessory
  end

  def boot(name, prepare: true)
    return original_boot(name, prepare: prepare) unless KAMAL.quadlet_enabled?

    with_lock do
      if name == "all"
        KAMAL.accessory_names.each { |accessory_name| boot(accessory_name) }
      else
        prepare(name) if prepare

        with_accessory(name) do |accessory, hosts|
          booted_hosts = Concurrent::Array.new
          on(hosts) do |host|
            booted_hosts << host.to_s if capture_with_info(*accessory.info(all: true, quiet: true)).strip.presence
          end

          if booted_hosts.any?
            say "Skipping booting `#{name}` on #{booted_hosts.sort.join(", ")}, a container already exists", :yellow
            hosts -= booted_hosts
          end

          directories(name)
          upload(name)

          on(hosts) do |host|
            execute *KAMAL.auditor.record("Booted #{name} accessory"), verbosity: :debug
            execute *accessory.ensure_env_directory
            upload! accessory.secrets_io, accessory.secrets_path, mode: "0600"

            # Write Quadlet .container file and start via systemd
            run_cmd = accessory.run(host: host)
            unit_name = accessory.service_name

            content = KAMAL.quadlet.container_file_content(
              unit_name: unit_name,
              image: accessory.image,
              run_args: run_cmd[2..],
              cmd: accessory.cmd
            )

            execute *KAMAL.quadlet.ensure_quadlet_directory
            upload! StringIO.new(content), KAMAL.quadlet.quadlet_file_path(unit_name)
            execute *KAMAL.quadlet.daemon_reload
            execute *KAMAL.quadlet.start_unit(unit_name)

            if accessory.running_proxy?
              target = capture_with_info(*accessory.container_id_for(container_name: accessory.service_name, only_running: true)).strip
              execute *accessory.deploy(target: target)
            end
          end
        end
      end
    end
  end

  def start(name)
    return original_start(name) unless KAMAL.quadlet_enabled?

    with_lock do
      with_accessory(name) do |accessory, hosts|
        on(hosts) do
          execute *KAMAL.auditor.record("Started #{name} accessory"), verbosity: :debug
          execute *KAMAL.quadlet.start_unit(accessory.service_name)

          if accessory.running_proxy?
            target = capture_with_info(*accessory.container_id_for(container_name: accessory.service_name, only_running: true)).strip
            execute *accessory.deploy(target: target)
          end
        end
      end
    end
  end

  def stop(name)
    return original_stop(name) unless KAMAL.quadlet_enabled?

    with_lock do
      with_accessory(name) do |accessory, hosts|
        on(hosts) do
          execute *KAMAL.auditor.record("Stopped #{name} accessory"), verbosity: :debug
          execute *KAMAL.quadlet.stop_unit(accessory.service_name), raise_on_non_zero_exit: false

          if accessory.running_proxy?
            target = capture_with_info(*accessory.container_id_for(container_name: accessory.service_name, only_running: true)).strip
            execute *accessory.remove if target
          end
        end
      end
    end
  end

  private

  def remove_accessory(name)
    return original_remove_accessory(name) unless KAMAL.quadlet_enabled?

    with_accessory(name) do |accessory, hosts|
      stop(name)
      on(hosts) do
        execute *KAMAL.quadlet.remove_quadlet_file(accessory.service_name)
        execute *KAMAL.quadlet.daemon_reload
      end
    end
    remove_container(name)
    remove_image(name)
    remove_service_directory(name)
  end
end
