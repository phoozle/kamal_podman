Kamal::Configuration.class_eval do
  def proxy_image
    "docker.io/basecamp/kamal-proxy:#{Kamal::Configuration::PROXY_MINIMUM_VERSION}"
  end
end
