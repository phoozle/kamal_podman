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

  test "superuser?" do
    assert_equal \
      '[ "${EUID:-$(id -u)}" -eq 0 ] || sudo -nl podman >/dev/null',
      new_command.superuser?.join(" ")
  end

  test "root?" do
    assert_equal \
      '[ "${EUID:-$(id -u)}" -eq 0 ]',
      new_command.root?.join(" ")
  end

  test "in_podman_group?" do
    assert_equal "true", new_command.in_podman_group?.join(" ")
  end

  test "add_to_podman_group" do
    assert_equal "true", new_command.add_to_podman_group.join(" ")
  end

  test "refresh_session" do
    assert_equal "kill -HUP $PPID", new_command.refresh_session.join(" ")
  end

  test "install raises" do
    error = assert_raises(RuntimeError) { new_command.install }
    assert_match(/podman.io/, error.message)
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
