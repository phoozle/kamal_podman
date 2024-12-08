# TODO: consider if base class for container manager needed
class Kamal::Commands::Podman < Kamal::Commands::Base
  def install
    raise "Please see https://podman.io/docs/installation to install Podman"
  end

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

  # Do we have superuser access to install Podman and start system services?
  def superuser?
    [ '[ "${EUID:-$(id -u)}" -eq 0 ] || command -v sudo >/dev/null || command -v su >/dev/null' ]
  end

  def create_network
    podman :network, :create, :kamal
  end
end
