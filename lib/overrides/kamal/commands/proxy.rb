Kamal::Commands::Proxy.class_eval do
  def docker(*args)
    podman(*args)
  end
end
