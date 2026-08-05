# frozen_string_literal: true

Kamal::Commands::Base.class_eval do
  def docker(*args)
    podman(*args)
  end

  def podman(*args)
    args.compact.unshift :podman
  end

  # Upstream pairs the daemon check with `docker buildx version`. Podman has no buildx, so
  # the swapped command always fails. Only KAMAL.builder calls this today, but it is public
  # and inherited by every command class, so fix it at the root.
  def ensure_docker_installed
    podman "--version"
  end
end
