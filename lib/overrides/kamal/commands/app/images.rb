Kamal::Commands::App::Images.class_eval do
  def docker(*args)
    podman(*args)
  end
end
