# frozen_string_literal: true

class KamalPodman::Commands::Quadlet < Kamal::Commands::Base
  ROOTFUL_QUADLET_DIR = "/etc/containers/systemd"
  ROOTLESS_QUADLET_DIR = "$HOME/.config/containers/systemd"

  def quadlet_directory
    rootful? ? ROOTFUL_QUADLET_DIR : ROOTLESS_QUADLET_DIR
  end

  def quadlet_file_path(unit_name)
    "#{quadlet_directory}/#{unit_name}.container"
  end

  def ensure_quadlet_directory
    make_directory quadlet_directory
  end

  # Generate .container file content from the same args that podman run receives.
  # run_args: everything after [:podman, :run] from the command array
  # image: the container image (e.g. "docker.io/dhh/app:999")
  # cmd: optional command to run (e.g. "bin/jobs")
  def container_file_content(unit_name:, image:, run_args:, cmd: nil, restart_policy: "always")
    directives = KamalPodman::Commands::Quadlet::ArgParser.parse(run_args)
    resolve_relative_paths!(directives)
    exec_line = "Exec=#{cmd}\n" if cmd.present?

    <<~QUADLET
      [Unit]
      Description=#{unit_name}

      [Container]
      Image=#{image}
      Pull=never
      #{directives.join("\n")}
      #{exec_line}
      [Service]
      Restart=#{restart_policy}
      RestartSec=5s
      WorkingDirectory=#{working_directory}

      [Install]
      WantedBy=default.target
    QUADLET
  end

  def daemon_reload
    systemctl "daemon-reload"
  end

  def start_unit(unit_name)
    systemctl :start, "#{unit_name}.service"
  end

  def stop_unit(unit_name)
    systemctl :stop, "#{unit_name}.service"
  end

  def enable_unit(unit_name)
    systemctl :enable, "#{unit_name}.service"
  end

  def enable_and_start_unit(unit_name)
    systemctl :enable, "--now", "#{unit_name}.service"
  end

  def disable_unit(unit_name)
    systemctl :disable, "#{unit_name}.service"
  end

  def remove_quadlet_file(unit_name)
    [ :rm, "-f", quadlet_file_path(unit_name) ]
  end

  private
    # Quadlet resolves relative paths in EnvironmentFile relative to the
    # .container file directory, not the WorkingDirectory. We need to make
    # them absolute so they resolve correctly.
    def resolve_relative_paths!(directives)
      directives.map! do |d|
        if d.start_with?("EnvironmentFile=") && !d.start_with?("EnvironmentFile=/")
          path = d.delete_prefix("EnvironmentFile=")
          "EnvironmentFile=#{working_directory}/#{path}"
        else
          d
        end
      end
    end

    def rootful?
      config.ssh.user == "root"
    end

    def working_directory
      rootful? ? "/root" : "$HOME"
    end

    def systemctl(*args)
      if rootful?
        [ :systemctl, *args ]
      else
        [ :systemctl, "--user", *args ]
      end
    end
end
