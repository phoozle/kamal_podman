# frozen_string_literal: true

class KamalPodman::Commands::Builder < Kamal::Commands::Builder
  def local
    @local ||= KamalPodman::Commands::Builder::Local.new(config)
  end

  def ensure_docker_installed
    podman "--version"
  end

  def validate!
    if config.builder.remote
      raise KamalPodman::Error, "Podman does not support remote builders. Remove the `remote` option from your builder configuration."
    end

    if config.builder.arches.length > 1
      raise KamalPodman::Error, "Podman does not support multi-architecture builds. Configure a single architecture in your builder configuration."
    end

    if config.builder.cloud?
      raise KamalPodman::Error, "Podman does not support cloud builders. Remove the cloud driver from your builder configuration."
    end
  end
end
