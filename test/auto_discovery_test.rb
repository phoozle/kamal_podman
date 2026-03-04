require "test_helper"

class AutoDiscoveryTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
  end

  test "all Kamal::Commands::Base subclasses override docker to use podman" do
    config = Kamal::Configuration.new(@config, version: "999")
    uncovered = []

    ObjectSpace.each_object(Class).select { |c| c < Kamal::Commands::Base }.each do |klass|
      # Skip KamalPodman's own classes — they define podman natively
      next if klass.name&.start_with?("KamalPodman::")
      # Skip abstract base classes that aren't instantiated directly
      next if klass == Kamal::Commands::Builder::Base

      instance = begin
        case klass.name
        when "Kamal::Commands::App"
          klass.new(config, role: config.role(:web), host: "1.1.1.1")
        when "Kamal::Commands::Proxy"
          klass.new(config, host: "1.1.1.1")
        when "Kamal::Commands::Accessory"
          klass.new(config, name: config.accessories.first&.name || next)
        else
          klass.new(config)
        end
      rescue => e
        uncovered << "#{klass.name} (couldn't instantiate: #{e.message})"
        next
      end

      result = instance.docker(:version)
      unless result.is_a?(Array) && result.first == :podman
        uncovered << "#{klass.name}#docker returned #{result.inspect} instead of podman command"
      end
    end

    assert_empty uncovered, "The following classes are not covered by docker->podman overrides:\n#{uncovered.join("\n")}"
  end
end
