# frozen_string_literal: true

class KamalPodman::Commands::Builder < Kamal::Commands::Builder
  def local
    @local ||= KamalPodman::Commands::Builder::Local.new(config)
  end

  # Upstream strips the Kamal namespace to label the builder; ours lives under KamalPodman,
  # so without this `kamal-podman build details` reports the whole class path.
  def name
    target.class.to_s.remove("KamalPodman::Commands::Builder::").underscore.inquiry
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

    # Pack builds through the `pack` CLI, which writes the image into the Docker daemon.
    # The subsequent push would look for it in Podman's store and not find it, so reject
    # this at configuration time rather than failing mid-deploy.
    if config.builder.pack?
      raise KamalPodman::Error, "Podman does not support pack (buildpack) builders. Remove the `pack` option from your builder configuration."
    end
  end
end
