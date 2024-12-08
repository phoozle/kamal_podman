Kamal::Commands::Base.class_eval do
  def docker(*args)
    raise "Docker only command, podman not supported"
  end

  def podman(*args)
    args.compact.unshift :podman
  end
end
