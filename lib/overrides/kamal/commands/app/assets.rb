# frozen_string_literal: true

Kamal::Commands::App::Assets.module_eval do
  def extract_assets
    asset_container = "#{role.container_prefix}-assets"

    combine \
      make_directory(role.asset_extracted_directory),
      [ *docker(:container, :rm, asset_container, "2> /dev/null"), "|| true" ],
      docker(:container, :create, "--name", asset_container, config.absolute_image),
      docker(:container, :cp, "#{asset_container}:#{role.asset_path}/.", role.asset_extracted_directory),
      docker(:container, :rm, asset_container),
      by: "&&"
  end
end
