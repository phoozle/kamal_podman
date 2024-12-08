Kamal::Commands::Registry.class_eval do
  def docker(*args)
    podman(*args)
  end
end
