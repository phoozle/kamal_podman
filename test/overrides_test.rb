require "test_helper"

class BaseOverrideTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
  end

  test "docker delegates to podman" do
    assert_equal [ :podman, :ps ], new_command.docker(:ps)
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
      "podman container ls --all --filter 'name=^app-web-999$' --quiet",
      new_command.container_id_for(container_name: "app-web-999").join(" ")
  end

  test "container_id_for with only_running" do
    assert_equal \
      "podman container ls --filter 'name=^app-web-999$' --quiet",
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
      "podman run --detach --restart unless-stopped --name app-web-999 --network kamal --env KAMAL_CONTAINER_NAME=\"app-web-999\" --env KAMAL_VERSION=\"999\" --env KAMAL_HOST=\"1.1.1.1\" --env-file .kamal/apps/app/env/roles/web.env --log-opt max-size=\"10m\" --label service=\"app\" --label role=\"web\" --label destination docker.io/dhh/app:999",
      new_command.run.join(" ")
  end

  test "container_id_for_version" do
    assert_equal \
      "podman container ls --all --filter 'name=^app-web-999$' --quiet",
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
      :podman, :container, :rm, "app-web-assets", "2> /dev/null", "|| true", "&&",
      :podman, :container, :create, "--name", "app-web-assets", "docker.io/dhh/app:999", "&&",
      :podman, :container, :cp, "-L", "app-web-assets:/.", ".kamal/apps/app/assets/extracted/web-999", "&&",
      :podman, :container, :rm, "app-web-assets"
    ], new_command.extract_assets
  end

  private
    def new_command
      config = Kamal::Configuration.new(@config, version: "999")
      Kamal::Commands::App.new(config, role: config.role(:web), host: "1.1.1.1")
    end
end

class AppLoggingOverrideTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1", "1.1.1.2" ], builder: { "arch" => "amd64" }
    }
  end

  test "logs uses podman" do
    assert_match \
      /xargs podman logs --timestamps 2>&1/,
      new_command.logs.join(" ")
  end

  test "logs with since" do
    assert_match \
      /xargs podman logs --timestamps --since 1h 2>&1/,
      new_command.logs(since: "1h").join(" ")
  end

  test "logs with lines" do
    assert_match \
      /xargs podman logs --timestamps --tail 100 2>&1/,
      new_command.logs(lines: 100).join(" ")
  end

  test "logs with grep" do
    result = new_command.logs(grep: "error").join(" ")
    assert_match(/xargs podman logs --timestamps 2>&1/, result)
    assert_match(/grep 'error'/, result)
  end

  test "follow_logs uses podman" do
    result = new_command.follow_logs(host: "1.1.1.1").strip
    assert_match(/xargs podman logs --timestamps --follow 2>&1/, result)
    assert_no_match(/xargs docker logs/, result)
  end

  test "follow_logs with grep" do
    result = new_command.follow_logs(host: "1.1.1.1", grep: "error").strip
    assert_match(/xargs podman logs --timestamps --follow 2>&1/, result)
    assert_match(/grep "error"/, result)
  end

  private
    def new_command
      config = Kamal::Configuration.new(@config, version: "999")
      Kamal::Commands::App.new(config, role: config.role(:web), host: "1.1.1.1")
    end
end

class ProxyOverrideTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1", "1.1.1.2" ], builder: { "arch" => "amd64" }
    }
  end

  test "start" do
    assert_equal \
      "podman container start kamal-proxy",
      new_command.start.join(" ")
  end

  test "stop" do
    assert_equal \
      "podman container stop kamal-proxy",
      new_command.stop.join(" ")
  end

  test "info" do
    assert_equal \
      "podman ps --filter name=^kamal-proxy$",
      new_command.info.join(" ")
  end

  private
    def new_command
      Kamal::Commands::Proxy.new(Kamal::Configuration.new(@config, version: "999"), host: "1.1.1.1")
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

  test "dangling images" do
    assert_equal \
      "podman image prune --force --filter label=service=app",
      new_command.dangling_images.join(" ")
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

class AppHealthCheckOverrideTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
  end

  test "status uses podman" do
    result = new_command.status(version: "999").join(" ")
    assert_match(/podman container ls/, result)
    assert_match(/xargs podman inspect --format/, result)
    assert_no_match(/\bdocker\b/, result)
  end

  test "container_health_log uses podman" do
    result = new_command.container_health_log(version: "999").join(" ")
    assert_match(/podman container ls/, result)
    assert_match(/xargs podman inspect --format/, result)
    assert_no_match(/\bdocker\b/, result)
  end

  private
    def new_command
      config = Kamal::Configuration.new(@config, version: "999")
      Kamal::Commands::App.new(config, role: config.role(:web), host: "1.1.1.1")
    end
end

class AccessoryOverrideTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" },
      accessories: { "db" => { "image" => "mysql:8.0", "host" => "1.1.1.1", "port" => "3306",
        "env" => { "clear" => { "MYSQL_ROOT_HOST" => "%" } } } }
    }
  end

  test "run uses podman" do
    result = new_command.run.join(" ")
    assert_match(/^podman run --name app-db/, result)
    assert_no_match(/\bdocker run\b/, result)
  end

  test "start uses podman" do
    assert_equal \
      "podman container start app-db",
      new_command.start.join(" ")
  end

  test "stop uses podman" do
    assert_equal \
      "podman container stop app-db",
      new_command.stop.join(" ")
  end

  test "info uses podman" do
    result = new_command.info.join(" ")
    assert_match(/^podman ps/, result)
  end

  test "logs uses podman" do
    result = new_command.logs.join(" ")
    assert_match(/podman logs app-db/, result)
    assert_no_match(/\bdocker logs\b/, result)
  end

  test "follow_logs uses podman" do
    result = new_command.follow_logs.strip
    assert_match(/podman logs app-db/, result)
    assert_no_match(/\bdocker logs\b/, result)
  end

  test "execute_in_existing_container uses podman" do
    result = new_command.execute_in_existing_container("bash").join(" ")
    assert_match(/^podman exec/, result)
    assert_match(/app-db/, result)
  end

  test "execute_in_new_container uses podman" do
    result = new_command.execute_in_new_container("bash").join(" ")
    assert_match(/^podman run/, result)
  end

  test "pull_image uses podman" do
    assert_equal \
      "podman image pull mysql:8.0",
      new_command.pull_image.join(" ")
  end

  test "remove_container uses podman" do
    result = new_command.remove_container.join(" ")
    assert_match(/^podman container prune --force/, result)
  end

  test "remove_image uses podman" do
    assert_equal \
      "podman image rm --force mysql:8.0",
      new_command.remove_image.join(" ")
  end

  private
    def new_command
      config = Kamal::Configuration.new(@config, version: "999")
      Kamal::Commands::Accessory.new(config, name: :db)
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

  test "proxy boot image default" do
    assert_equal "docker.io/basecamp/kamal-proxy", new_config.proxy_boot.image_default
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
