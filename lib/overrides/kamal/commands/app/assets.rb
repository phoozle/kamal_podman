Kamal::Commands::App::Assets.class_eval do
  def docker(*args)
    podman(*args)
  end
end
