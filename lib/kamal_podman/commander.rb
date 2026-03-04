# frozen_string_literal: true

class KamalPodman::Commander < Kamal::Commander
  def builder
    @builder ||= KamalPodman::Commands::Builder.new(config).tap(&:validate!)
  end

  def podman
    @podman ||= KamalPodman::Commands::Podman.new(config)
  end

  def docker
    podman
  end
end
