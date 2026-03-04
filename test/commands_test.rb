require "test_helper"

class CommanderTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
    @commander = KamalPodman::Commander.new
    @commander.stubs(:config).returns(Kamal::Configuration.new(@config, version: "999"))
  end

  test "commander is a KamalPodman::Commander" do
    assert_kind_of KamalPodman::Commander, @commander
  end

  test "docker delegates to podman" do
    assert_equal @commander.podman, @commander.docker
  end

  test "podman" do
    assert_kind_of KamalPodman::Commands::Podman, @commander.podman
  end

  test "builder" do
    assert_kind_of KamalPodman::Commands::Builder, @commander.builder
  end
end

class PodmanCommandsTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
  end

  test "installed?" do
    assert_equal [ :podman, "-v" ], new_command.installed?
  end

  test "running?" do
    assert_equal [ :podman, :version ], new_command.running?
  end

  test "name" do
    assert_equal "Podman", new_command.name
  end

  test "create_network" do
    assert_equal [ :podman, :network, :create, :kamal ], new_command.create_network
  end

  private
    def new_command
      KamalPodman::Commands::Podman.new(Kamal::Configuration.new(@config, version: "999"))
    end
end

class BuilderCommandsTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
  end

  test "local" do
    assert_kind_of KamalPodman::Commands::Builder::Local, new_command.local
  end

  test "ensure_docker_installed" do
    assert_equal [ :podman, "--version" ], new_command.ensure_docker_installed
  end

  test "validate! passes for single arch" do
    assert_nothing_raised { new_command.validate! }
  end

  test "validate! raises for remote builder" do
    config = @config.merge(builder: { "arch" => "amd64", "remote" => "ssh://builder-host" })
    builder = KamalPodman::Commands::Builder.new(Kamal::Configuration.new(config, version: "999"))
    error = assert_raises(KamalPodman::Error) { builder.validate! }
    assert_match(/remote builders/, error.message)
  end

  test "validate! raises for multi-arch" do
    config = @config.merge(builder: { "arch" => [ "amd64", "arm64" ] })
    builder = KamalPodman::Commands::Builder.new(Kamal::Configuration.new(config, version: "999"))
    error = assert_raises(KamalPodman::Error) { builder.validate! }
    assert_match(/multi-architecture/, error.message)
  end

  test "validate! raises for cloud builder" do
    config = @config.merge(builder: { "arch" => "amd64", "driver" => "cloud-docker" })
    builder = KamalPodman::Commands::Builder.new(Kamal::Configuration.new(config, version: "999"))
    error = assert_raises(KamalPodman::Error) { builder.validate! }
    assert_match(/cloud builders/, error.message)
  end

  private
    def new_command
      KamalPodman::Commands::Builder.new(Kamal::Configuration.new(@config, version: "999"))
    end
end

class BuilderLocalCommandsTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
  end

  test "push" do
    assert_equal \
      "podman build --platform linux/amd64 -t docker.io/dhh/app:999 -t docker.io/dhh/app:latest --label service=\"app\" --file Dockerfile . && podman push docker.io/dhh/app:999",
      new_command.push.join(" ")
  end

  test "docker delegates to podman" do
    assert_equal [ :podman, :ps ], new_command.docker(:ps)
  end

  test "create is a no-op" do
    assert_nil new_command.create
  end

  test "inspect_builder is a no-op" do
    assert_nil new_command.inspect_builder
  end

  test "remove is a no-op" do
    assert_nil new_command.remove
  end

  private
    def new_command
      KamalPodman::Commands::Builder::Local.new(Kamal::Configuration.new(@config, version: "999"))
    end
end

class VersionCompatibilityTest < ActiveSupport::TestCase
  test "KAMAL_COMPATIBLE_VERSION matches pinned Kamal version" do
    assert_equal Kamal::VERSION, KamalPodman::KAMAL_COMPATIBLE_VERSION
  end
end
