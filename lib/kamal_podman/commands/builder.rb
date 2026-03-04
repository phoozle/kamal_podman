class KamalPodman::Commands::Builder < Kamal::Commands::Builder
  def local
    @local ||= KamalPodman::Commands::Builder::Local.new(config)
  end

  def ensure_docker_installed
    podman "--version"
  end
end
