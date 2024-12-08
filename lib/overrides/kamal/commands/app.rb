Kamal::Commands::App.class_eval do
  def docker(*args)
    podman(*args)
  end
end
