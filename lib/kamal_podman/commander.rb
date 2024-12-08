class KamalPodman::Commander < Kamal::Commander
  def builder
    @builder ||= KamalPodman::Commands::Builder.new(config)
  end

  def podman
    @podman ||= KamalPodman::Commands::Podman.new(config)
  end

  def docker
    podman
  end
end
