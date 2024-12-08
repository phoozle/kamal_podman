Kamal::Commands::Base.class_eval do
  def docker(*args)
    raise "Docker only command, podman not supported"
  end

  def podman(*args)
    args.compact.unshift :podman
  end

  def container_id_for(container_name:, only_running: false)
    podman :container, :ls, *("--all" unless only_running), "--filter", "name=^#{container_name}$", "--quiet"
  end
end
