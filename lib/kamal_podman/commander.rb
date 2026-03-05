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

  def quadlet
    @quadlet ||= KamalPodman::Commands::Quadlet.new(config)
  end

  def quadlet_enabled?
    config.raw_config[:"x-quadlet"] == true
  end
end
