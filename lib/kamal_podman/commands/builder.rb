class KamalPodman::Commands::Builder < Kamal::Commands::Builder
  def local
    @local ||= KamalPodman::Commands::Builder::Local.new(config)
  end

  def ensure_local_dependencies_installed
    # TODO: when using remote check server version
    podman "--version"
  end
end
