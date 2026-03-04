# frozen_string_literal: true

class KamalPodman::Commands::Builder::Local < Kamal::Commands::Builder::Base
  def push(export_action = "registry", tag_as_dirty: false, no_cache: false)
    combine \
      podman(:build,
        *platform_options(arches),
        *build_tag_options(tag_as_dirty: tag_as_dirty),
        *build_options,
        *([ "--no-cache" ] if no_cache),
        build_context
      ),
      podman(:push, config.absolute_image)
  end

  def create; end
  def inspect_builder; end
  def remove; end
end
