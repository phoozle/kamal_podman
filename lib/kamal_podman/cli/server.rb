# frozen_string_literal: true

class KamalPodman::Cli::Server < Kamal::Cli::Server
  desc "bootstrap", "Set up Podman to run Kamal apps"
  def bootstrap
    with_lock do
      missing = []

      on(KAMAL.hosts) do |host|
        unless execute(*KAMAL.podman.installed?, raise_on_non_zero_exit: false)
          missing << host
        end
      end

      if missing.any?
        raise KamalPodman::Error, "Podman is not installed on #{missing.join(", ")}. " \
              "Install Podman manually: https://podman.io/docs/installation"
      end

      # Enable lingering for rootless Quadlet so systemd user services
      # survive after the SSH session disconnects
      if KAMAL.quadlet_enabled? && KAMAL.config.ssh.user != "root"
        on(KAMAL.hosts) do
          execute :loginctl, "enable-linger", KAMAL.config.ssh.user
        end
      end

      run_hook "docker-setup"
    end
  end
end
