class KamalPodman::Cli::Server < Kamal::Cli::Server
  desc "bootstrap", "Set up Podman to run Kamal apps"
  def bootstrap
    with_lock do
      missing = []

      on(KAMAL.hosts | KAMAL.accessory_hosts) do |host|
        unless execute(*KAMAL.podman.installed?, raise_on_non_zero_exit: false)
          if execute(*KAMAL.podman.superuser?, raise_on_non_zero_exit: false)
            info "Missing Podman on #{host}. Installing…"
            execute *KAMAL.podman.install
          else
            missing << host
          end
        end
      end

      if missing.any?
        raise "Podman is not installed on #{missing.join(", ")} and can't be automatically installed without having root access and either `wget` or `curl`. Install Docker manually: https://podman.io/docs/installation"
      end

      run_hook "docker-setup"
    end
  end
end
