class KamalPodman::Commands::Builder::Local < Kamal::Commands::Builder::Base
  def create; end

  def push
    combine \
      podman(:build,
        *platform_options(arches),
        *build_options,
        build_context
      ),
      podman(:push, config.absolute_image)
  end

  def inspect_builder; end
end
