require "test_helper"

# Safety nets for Kamal upgrades. The binary swap on Kamal::Commands::Base means new upstream
# commands become podman commands for free — but "starts with podman" is not the same as
# "valid podman". These tests check both halves.
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

# Docker syntax that Podman rejects outright. Swapping the binary is not enough for these —
# each needs a Layer 2 override. Verified against real podman; the container-state errors
# read "Error: unknown container state: <state>: invalid argument".
class PodmanSyntaxTest < ActiveSupport::TestCase
  INVALID_SYNTAX = {
    /\bpodman buildx\b/ => "podman has no buildx",
    /\bpodman context\b/ => "podman has no context command",
    /status=restarting\b/ => "not a podman container state",
    /status=dead\b/ => "not a podman container state",
    /status=stopping\b/ => "not a podman container state"
  }

  setup do
    @config = Kamal::Configuration.new({
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" },
      accessories: { "db" => { "image" => "mysql:8.0", "host" => "1.1.1.1", "port" => "3306" } }
    }, version: "999")
  end

  test "no command emits docker-only syntax that podman rejects" do
    offenders = []

    each_emitted_command do |source, command|
      INVALID_SYNTAX.each do |pattern, reason|
        offenders << "#{source}: #{reason}\n    #{command}" if command.match?(pattern)
      end
    end

    assert_empty offenders, "Commands using syntax podman rejects:\n#{offenders.join("\n")}"
  end

  test "sweep actually reaches the commands it claims to cover" do
    sources = []
    each_emitted_command { |source, _| sources << source }

    # Guard against the sweep silently degrading to nothing if an upstream signature changes
    assert_operator sources.size, :>=, 50, "Sweep only collected #{sources.size} commands"
    %w[App Accessory Proxy Prune Registry Builder].each do |label|
      assert sources.any? { |source| source.start_with?("#{label}#") }, "Sweep never reached #{label}"
    end
  end

  private
    def command_instances
      {
        "App" => Kamal::Commands::App.new(@config, role: @config.role(:web), host: "1.1.1.1"),
        "Accessory" => Kamal::Commands::Accessory.new(@config, name: :db),
        "Proxy" => Kamal::Commands::Proxy.new(@config, host: "1.1.1.1"),
        "Prune" => Kamal::Commands::Prune.new(@config),
        "Registry" => Kamal::Commands::Registry.new(@config),
        "Lock" => Kamal::Commands::Lock.new(@config),
        "Auditor" => Kamal::Commands::Auditor.new(@config),
        "Server" => Kamal::Commands::Server.new(@config),
        "Builder" => KamalPodman::Commands::Builder.new(@config)
      }
    end

    # Calls every public command-building method, filling required positional args with a
    # version-shaped string. Methods needing other shapes just raise and are skipped.
    def each_emitted_command
      command_instances.each do |label, instance|
        methods_for(instance).each do |method_name|
          method = begin
            instance.method(method_name)
          rescue NameError
            next
          end
          next unless method.owner.to_s.start_with?("Kamal", "KamalPodman")

          args = Array.new(method.parameters.count { |type, _| type == :req }, "999")
          kwargs = method.parameters.filter_map { |type, name| [ name, stub_value_for(name) ] if type == :keyreq }.to_h

          begin
            result = kwargs.any? ?
              instance.public_send(method_name, *args, **kwargs) :
              instance.public_send(method_name, *args)
          rescue StandardError
            next
          end

          command = Array(result).flatten.join(" ")
          yield "#{label}##{method_name}", command if command.include?("podman")
        end
      end
    end

    def methods_for(instance)
      (instance.public_methods(false) + instance.class.superclass.public_instance_methods(false)).uniq
    end

    def stub_value_for(parameter_name)
      parameter_name == :retain ? 1 : "999"
    end
end
