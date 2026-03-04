class KamalPodman::Commands::Podman < Kamal::Commands::Base
  # Checks the Podman client version. Fails if Podman is not installed.
  def installed?
    podman "-v"
  end

  def name
    "Podman"
  end

  # Checks the Podman server version. Fails if Podman is not running.
  def running?
    podman :version
  end

  def create_network
    podman :network, :create, :kamal
  end
end
