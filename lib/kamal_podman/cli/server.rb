class KamalPodman::Cli::Server < Kamal::Cli::Server
  desc "bootstrap", "Set up Podman to run Kamal apps"
  def bootstrap
    with_lock do
      missing = []

      on(KAMAL.hosts) do |host|
        unless execute(*KAMAL.podman.installed?, raise_on_non_zero_exit: false)
          if execute(*KAMAL.podman.superuser?, raise_on_non_zero_exit: false)
            info "Missing Podman on #{host}. Installing…"
            execute *KAMAL.podman.install

            unless execute(*KAMAL.podman.root?, raise_on_non_zero_exit: false) ||
                   execute(*KAMAL.podman.in_podman_group?, raise_on_non_zero_exit: false)
              execute *KAMAL.podman.add_to_podman_group
              begin
                execute *KAMAL.podman.refresh_session
              rescue IOError
                info "Session refreshed due to group change."
              end
            end
          else
            missing << host
          end
        end
      end

      if missing.any?
        raise "Podman is not installed on #{missing.join(", ")} and can't be automatically installed without having root access. Install Podman manually: https://podman.io/docs/installation"
      end

      run_hook "docker-setup"
    end
  end
end
