# frozen_string_literal: true

Kamal::Configuration::Proxy::Boot.class_eval do
  def image_default
    "docker.io/basecamp/kamal-proxy"
  end
end
