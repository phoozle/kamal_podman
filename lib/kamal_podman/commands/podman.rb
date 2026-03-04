class KamalPodman::Commands::Podman < Kamal::Commands::Base
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
    [ '[ "${EUID:-$(id -u)}" -eq 0 ] || sudo -nl podman >/dev/null' ]
  end

  def root?
    [ '[ "${EUID:-$(id -u)}" -eq 0 ]' ]
  end

  def in_podman_group?
    # Podman supports rootless operation out of the box — no group required
    [ "true" ]
  end

  def add_to_podman_group
    # No-op for Podman (rootless by default)
    [ "true" ]
  end

  def refresh_session
    [ "kill -HUP $PPID" ]
  end

  def create_network
    podman :network, :create, :kamal
  end
end
