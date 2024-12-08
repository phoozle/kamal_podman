# frozen_string_literal: true

require_relative "kamal_podman/version"

require "kamal"

module KamalPodman
  class Error < StandardError; end
end

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/overrides")
loader.setup # ready!
loader.eager_load_namespace(Kamal::Cli)

Dir.glob("#{__dir__}/overrides/**/*.rb").each do |c|
  load(c)
end

require_relative "kamal_podman/override"
