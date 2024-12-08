class KamalPodman::Commands::Builder::Local < Kamal::Commands::Builder::Base
  def push
    combine \
      podman(:build,
        *platform_options(arches),
        *build_options,
        build_context
      ),
      podman(:push, config.absolute_image)
  end

  def docker(*args)
    podman(*args)
  end

  def create; end
  def inspect_builder; end
  def remove; end
end
