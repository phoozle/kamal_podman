require "test_helper"

class BaseOverrideTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
  end

  test "docker raises to catch missed overrides" do
    error = assert_raises(RuntimeError) { new_command.docker(:ps) }
    assert_match /podman not supported/, error.message
  end

  test "podman" do
    assert_equal [ :podman, :ps ], new_command.podman(:ps)
  end

  test "podman with multiple args" do
    assert_equal [ :podman, :container, :ls, "--all" ], new_command.podman(:container, :ls, "--all")
  end

  test "podman compacts nil args" do
    assert_equal [ :podman, :ps ], new_command.podman(:ps, nil)
  end

  test "container_id_for" do
    assert_equal \
      "podman container ls --all --filter name=^app-web-999$ --quiet",
      new_command.container_id_for(container_name: "app-web-999").join(" ")
  end

  test "container_id_for with only_running" do
    assert_equal \
      "podman container ls --filter name=^app-web-999$ --quiet",
      new_command.container_id_for(container_name: "app-web-999", only_running: true).join(" ")
  end

  private
    def new_command
      Kamal::Commands::Base.new(Kamal::Configuration.new(@config, version: "999"))
    end
end

class AppOverrideTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1", "1.1.1.2" ], builder: { "arch" => "amd64" }
    }
  end

  test "run" do
    assert_equal \
      "podman run --detach --restart unless-stopped --name app-web-999 --network kamal -e KAMAL_CONTAINER_NAME=\"app-web-999\" -e KAMAL_VERSION=\"999\" --env-file .kamal/apps/app/env/roles/web.env --log-opt max-size=\"10m\" --label service=\"app\" --label role=\"web\" --label destination docker.io/dhh/app:999",
      new_command.run.join(" ")
  end

  test "container_id_for_version" do
    assert_equal \
      "podman container ls --all --filter name=^app-web-999$ --quiet",
      new_command.container_id_for_version(999).join(" ")
  end

  test "list_images" do
    assert_equal \
      "podman image ls docker.io/dhh/app",
      new_command.list_images.join(" ")
  end

  test "extract_assets" do
    assert_equal [
      :mkdir, "-p", ".kamal/apps/app/assets/extracted/web-999", "&&",
      :podman, :stop, "-t 1", "app-web-assets", "2> /dev/null", "|| true", "&&",
      :podman, :run, "--name", "app-web-assets", "--detach", "--rm", "--entrypoint", "sleep", "docker.io/dhh/app:999", "1000000", "&&",
      :podman, :cp, "-L", "app-web-assets:/.", ".kamal/apps/app/assets/extracted/web-999", "&&",
      :podman, :stop, "-t 1", "app-web-assets"
    ], new_command.extract_assets
  end

  private
    def new_command
      config = Kamal::Configuration.new(@config, version: "999")
      Kamal::Commands::App.new(config, role: config.role(:web), host: "1.1.1.1")
    end
end

class AppModulesOverrideTest < ActiveSupport::TestCase
  test "App::Containers overrides docker" do
    assert Kamal::Commands::App::Containers.method_defined?(:docker, false)
  end

  test "App::Proxy overrides docker" do
    assert Kamal::Commands::App::Proxy.method_defined?(:docker, false)
  end

  test "App::Assets overrides docker" do
    assert Kamal::Commands::App::Assets.method_defined?(:docker, false)
  end

  test "App::Images overrides docker" do
    assert Kamal::Commands::App::Images.method_defined?(:docker, false)
  end
end

class ProxyOverrideTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1", "1.1.1.2" ], builder: { "arch" => "amd64" }
    }
  end

  test "run" do
    assert_equal \
      "podman run --name kamal-proxy --network kamal --detach --restart unless-stopped --volume kamal-proxy-config:/home/kamal-proxy/.config/kamal-proxy $(cat .kamal/proxy/options || echo \"--publish 80:80 --publish 443:443 --log-opt max-size=10m\") docker.io/basecamp/kamal-proxy:v0.8.2",
      new_command.run.join(" ")
  end

  private
    def new_command
      Kamal::Commands::Proxy.new(Kamal::Configuration.new(@config, version: "999"))
    end
end

class RegistryOverrideTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
  end

  test "login" do
    assert_equal \
      "podman login docker.io -u \"user\" -p \"pw\"",
      new_command.login.join(" ")
  end

  test "logout" do
    assert_equal \
      "podman logout docker.io",
      new_command.logout.join(" ")
  end

  private
    def new_command
      Kamal::Commands::Registry.new(Kamal::Configuration.new(@config))
    end
end

class PruneOverrideTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
  end

  test "tagged images" do
    assert_equal \
      "podman image ls --filter label=service=app --format '{{.ID}} {{.Repository}}:{{.Tag}}' | grep -v -w \"$(podman container ls -a --format '{{.Image}}\\|' --filter label=service=app | tr -d '\\n')docker.io/dhh/app:latest\\|docker.io/dhh/app:<none>\" | while read image tag; do podman rmi $tag; done",
      new_command.tagged_images.join(" ")
  end

  test "app containers" do
    assert_equal \
      "podman ps -q -a --filter label=service=app --filter status=created --filter status=exited --filter status=dead | tail -n +6 | while read container_id; do podman rm $container_id; done",
      new_command.app_containers(retain: 5).join(" ")

    assert_equal \
      "podman ps -q -a --filter label=service=app --filter status=created --filter status=exited --filter status=dead | tail -n +4 | while read container_id; do podman rm $container_id; done",
      new_command.app_containers(retain: 3).join(" ")
  end

  private
    def new_command
      Kamal::Commands::Prune.new(Kamal::Configuration.new(@config, version: "999"))
    end
end

class ConfigurationOverrideTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
  end

  test "default registry is docker.io" do
    assert_equal "docker.io", new_config.registry.server
  end

  test "proxy image" do
    assert_equal \
      "docker.io/basecamp/kamal-proxy:#{Kamal::Configuration::PROXY_MINIMUM_VERSION}",
      new_config.proxy_image
  end

  private
    def new_config
      Kamal::Configuration.new(@config, version: "999")
    end
end

class CliMainOverrideTest < ActiveSupport::TestCase
  test "server subcommand" do
    assert_equal KamalPodman::Cli::Server, Kamal::Cli::Main.subcommand_classes["server"]
  end
end
