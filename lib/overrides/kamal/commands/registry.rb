# frozen_string_literal: true

Kamal::Commands::Registry.class_eval do
  # Same reason as configuration/registry.rb: Podman only resolves a bare `registry:3` when
  # the host happens to set unqualified-search-registries. Name the image explicitly.
  def setup(registry_config: nil)
    registry_config ||= config.registry

    combine \
      podman(:start, "kamal-docker-registry"),
      podman(:run, "--detach", "-p", "127.0.0.1:#{registry_config.local_port}:5000", "--name", "kamal-docker-registry", "docker.io/library/registry:3"),
      by: "||"
  end
end
