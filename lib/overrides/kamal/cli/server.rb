# frozen_string_literal: true

# Patch bootstrap on Kamal::Cli::Server itself rather than registering a subclass as the
# `server` subcommand. `kamal-podman setup` reaches bootstrap through Thor's namespace
# lookup ("kamal:cli:server:bootstrap"), which resolves to Kamal::Cli::Server and would
# bypass a subclass entirely. Kamal::Cli::Base#command also looks the running class up in
# Kamal::Cli::Main.subcommand_classes, so swapping that registration breaks every command
# wrapped in `modify`.
Kamal::Cli::Server.class_eval do
  desc "bootstrap", "Set up Podman to run Kamal apps"
  def bootstrap
    modify(lock: true) do
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

      run_hook "docker-setup"
    end
  end
end
