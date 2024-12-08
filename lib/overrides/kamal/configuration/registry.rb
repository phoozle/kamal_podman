Kamal::Configuration::Registry.class_eval do
  DEFAULT_REGISTRY = "docker.io"

  def server
    registry_config["server"] || DEFAULT_REGISTRY
  end
end
