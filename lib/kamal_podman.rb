# frozen_string_literal: true

require_relative "kamal_podman/version"

require "kamal"

module KamalPodman
  class Error < StandardError; end

  KAMAL_COMPATIBLE_VERSION = "2.10.1"

  unless Kamal::VERSION == KAMAL_COMPATIBLE_VERSION
    warn "[kamal_podman] WARNING: Built for Kamal #{KAMAL_COMPATIBLE_VERSION}, " \
         "running against #{Kamal::VERSION}. Overrides may be incompatible."
  end
end

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/overrides")
loader.setup # ready!
loader.eager_load_namespace(Kamal::Cli)

Dir.glob("#{__dir__}/overrides/**/*.rb").each do |c|
  load(c)
end

require_relative "kamal_podman/override"
