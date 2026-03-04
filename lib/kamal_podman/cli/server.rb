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
        raise "Podman is not installed on #{missing.join(", ")}. " \
              "Install Podman manually: https://podman.io/docs/installation"
      end

      run_hook "docker-setup"
    end
  end
end
