Kamal::Commands::App::Containers.class_eval do
  def docker(*args)
    podman(*args)
  end
end
