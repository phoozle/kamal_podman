# frozen_string_literal: true

Kamal::Cli::App::Boot.class_eval do
  private

  alias_method :original_start_new_version, :start_new_version

  def start_new_version
    return original_start_new_version unless KAMAL.quadlet_enabled?

    audit "Booted app version #{version}"
    hostname = "#{host.to_s[0...51].chomp(".")}-#{SecureRandom.hex(6)}"

    execute *app.ensure_env_directory
    upload! role.secrets_io(host), role.secrets_path, mode: "0600"

    # Build the podman run command to extract flags
    run_cmd = app.run(hostname: hostname)
    unit_name = app.container_name

    content = KAMAL.quadlet.container_file_content(
      unit_name: unit_name,
      image: KAMAL.config.absolute_image,
      run_args: run_cmd[2..],
      cmd: role.cmd
    )

    execute *KAMAL.quadlet.ensure_quadlet_directory
    upload! StringIO.new(content), KAMAL.quadlet.quadlet_file_path(unit_name)
    execute *KAMAL.quadlet.daemon_reload
    execute *KAMAL.quadlet.start_unit(unit_name)

    if running_proxy?
      endpoint = capture_with_info(*app.container_id_for_version(version)).strip
      raise Kamal::Cli::BootError, "Failed to get endpoint for #{role} on #{host}, did the container boot?" if endpoint.empty?
      execute *app.deploy(target: endpoint)
    else
      Kamal::Cli::Healthcheck::Poller.wait_for_healthy { capture_with_info(*app.status(version: version)) }
    end
  rescue => e
    error "Failed to boot #{role} on #{host}"
    raise e
  end

  alias_method :original_stop_new_version, :stop_new_version

  def stop_new_version
    return original_stop_new_version unless KAMAL.quadlet_enabled?
    execute *KAMAL.quadlet.stop_unit(app.container_name), raise_on_non_zero_exit: false
  end

  alias_method :original_stop_old_version, :stop_old_version

  def stop_old_version(version)
    return original_stop_old_version(version) unless KAMAL.quadlet_enabled?
    execute *KAMAL.quadlet.stop_unit(app.container_name(version)), raise_on_non_zero_exit: false
    execute *app.clean_up_assets if assets?
    execute *app.clean_up_error_pages if KAMAL.config.error_pages_path
  end
end
