Kamal::Commands::Prune.class_eval do
  def docker(*args)
    podman(*args)
  end

  def tagged_images
    pipe \
      podman(:image, :ls, *service_filter, "--format", "'{{.ID}} {{.Repository}}:{{.Tag}}'"),
      grep("-v -w \"#{active_image_list}\""),
      "while read image tag; do podman rmi $tag; done"
  end

  def app_containers(retain:)
    pipe \
      podman(:ps, "-q", "-a", *service_filter, *stopped_containers_filters),
      "tail -n +#{retain + 1}",
      "while read container_id; do podman rm $container_id; done"
  end

  private
    def active_image_list
      # Pull the images that are used by any containers
      # Append repo:latest - to avoid deleting the latest tag
      # Append repo:<none> - to avoid deleting dangling images that are in use. Unused dangling images are deleted separately
      "$(podman container ls -a --format '{{.Image}}\\|' --filter label=service=#{config.service} | tr -d '\\n')#{config.latest_image}\\|#{config.repository}:<none>"
    end
end
