# frozen_string_literal: true

require "test_helper"

class QuadletArgParserTest < ActiveSupport::TestCase
  test "parses --name" do
    assert_includes parse("--name", "app-web-999"), "ContainerName=app-web-999"
  end

  test "parses --network" do
    assert_includes parse("--network", "kamal"), "Network=kamal"
  end

  test "parses --env" do
    result = parse("--env", "FOO=bar", "--env", "BAZ=qux")
    assert_includes result, "Environment=FOO=bar"
    assert_includes result, "Environment=BAZ=qux"
  end

  test "parses -e shorthand" do
    assert_includes parse("-e", "FOO=bar"), "Environment=FOO=bar"
  end

  test "parses --env-file" do
    assert_includes parse("--env-file", "/path/to/env"), "EnvironmentFile=/path/to/env"
  end

  test "parses --volume" do
    assert_includes parse("--volume", "/host:/container"), "Volume=/host:/container"
  end

  test "parses -v shorthand" do
    assert_includes parse("-v", "/host:/container"), "Volume=/host:/container"
  end

  test "parses --publish" do
    assert_includes parse("--publish", "80:3000"), "PublishPort=80:3000"
  end

  test "parses -p shorthand" do
    assert_includes parse("-p", "80:3000"), "PublishPort=80:3000"
  end

  test "parses --label" do
    assert_includes parse("--label", "service=app"), "Label=service=app"
  end

  test "parses --log-opt as PodmanArgs" do
    assert_includes parse("--log-opt", "max-size=10m"), "PodmanArgs=--log-opt max-size=10m"
  end

  test "parses --log-driver" do
    assert_includes parse("--log-driver", "journald"), "LogDriver=journald"
  end

  test "parses --hostname" do
    assert_includes parse("--hostname", "myhost"), "HostName=myhost"
  end

  test "skips --detach" do
    result = parse("--detach", "--name", "app")
    assert_equal [ "ContainerName=app" ], result
  end

  test "skips --restart with value" do
    result = parse("--restart", "unless-stopped", "--name", "app")
    assert_equal [ "ContainerName=app" ], result
  end

  test "skips --restart=value" do
    result = parse("--restart=unless-stopped", "--name", "app")
    assert_equal [ "ContainerName=app" ], result
  end

  test "skips --restart with space-joined value" do
    result = parse("--restart unless-stopped", "--name", "app")
    assert_equal [ "ContainerName=app" ], result
  end

  test "unknown --flag=value passes as PodmanArgs" do
    assert_includes parse("--memory=512m"), "PodmanArgs=--memory=512m"
  end

  test "unknown --flag with value passes as PodmanArgs" do
    assert_includes parse("--cpus", "2"), "PodmanArgs=--cpus 2"
  end

  test "unknown --flag without value passes as PodmanArgs" do
    assert_includes parse("--rm"), "PodmanArgs=--rm"
  end

  test "skips positional args" do
    result = parse("--name", "app", "docker.io/dhh/app:999")
    assert_equal [ "ContainerName=app" ], result
  end

  test "parses full run args like Kamal produces" do
    args = %w[
      --detach --restart unless-stopped
      --name app-web-999 --network kamal
      --env KAMAL_CONTAINER_NAME=app-web-999
      --env KAMAL_VERSION=999
      --env-file .kamal/apps/app/env/roles/web.env
      --log-opt max-size=10m
      --label service=app --label role=web
      docker.io/dhh/app:999
    ]

    result = parse(*args)

    assert_includes result, "ContainerName=app-web-999"
    assert_includes result, "Network=kamal"
    assert_includes result, "Environment=KAMAL_CONTAINER_NAME=app-web-999"
    assert_includes result, "Environment=KAMAL_VERSION=999"
    assert_includes result, "EnvironmentFile=.kamal/apps/app/env/roles/web.env"
    assert_includes result, "PodmanArgs=--log-opt max-size=10m"
    assert_includes result, "Label=service=app"
    assert_includes result, "Label=role=web"

    assert_not result.any? { |d| d.include?("detach") }
    assert_not result.any? { |d| d.include?("restart") }
    assert_not result.any? { |d| d.include?("docker.io/dhh/app:999") }
  end

  private
    def parse(*args)
      KamalPodman::Commands::Quadlet::ArgParser.parse(args)
    end
end

class QuadletCommandsTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
  end

  test "quadlet_directory rootful" do
    assert_equal "/etc/containers/systemd", new_command.quadlet_directory
  end

  test "quadlet_directory rootless" do
    assert_equal "$HOME/.config/containers/systemd", new_command(ssh_user: "deploy").quadlet_directory
  end

  test "quadlet_file_path rootful" do
    assert_equal "/etc/containers/systemd/app-web-999.container",
      new_command.quadlet_file_path("app-web-999")
  end

  test "quadlet_file_path rootless" do
    assert_equal "$HOME/.config/containers/systemd/app-web-999.container",
      new_command(ssh_user: "deploy").quadlet_file_path("app-web-999")
  end

  test "ensure_quadlet_directory rootful" do
    assert_equal \
      "mkdir -p /etc/containers/systemd",
      new_command.ensure_quadlet_directory.join(" ")
  end

  test "ensure_quadlet_directory rootless" do
    assert_equal \
      "mkdir -p $HOME/.config/containers/systemd",
      new_command(ssh_user: "deploy").ensure_quadlet_directory.join(" ")
  end

  test "daemon_reload rootful" do
    assert_equal [ :systemctl, "daemon-reload" ], new_command.daemon_reload
  end

  test "daemon_reload rootless" do
    assert_equal [ :systemctl, "--user", "daemon-reload" ], new_command(ssh_user: "deploy").daemon_reload
  end

  test "start_unit rootful" do
    assert_equal [ :systemctl, :start, "app-web-999.service" ], new_command.start_unit("app-web-999")
  end

  test "start_unit rootless" do
    assert_equal [ :systemctl, "--user", :start, "app-web-999.service" ],
      new_command(ssh_user: "deploy").start_unit("app-web-999")
  end

  test "stop_unit rootful" do
    assert_equal [ :systemctl, :stop, "app-web-999.service" ], new_command.stop_unit("app-web-999")
  end

  test "stop_unit rootless" do
    assert_equal [ :systemctl, "--user", :stop, "app-web-999.service" ],
      new_command(ssh_user: "deploy").stop_unit("app-web-999")
  end

  test "enable_unit" do
    assert_equal [ :systemctl, :enable, "app-web-999.service" ], new_command.enable_unit("app-web-999")
  end

  test "enable_and_start_unit" do
    assert_equal [ :systemctl, :enable, "--now", "app-web-999.service" ],
      new_command.enable_and_start_unit("app-web-999")
  end

  test "disable_unit" do
    assert_equal [ :systemctl, :disable, "app-web-999.service" ], new_command.disable_unit("app-web-999")
  end

  test "remove_quadlet_file rootful" do
    assert_equal [ :rm, "-f", "/etc/containers/systemd/app-web-999.container" ],
      new_command.remove_quadlet_file("app-web-999")
  end

  test "remove_quadlet_file rootless" do
    assert_equal [ :rm, "-f", "$HOME/.config/containers/systemd/app-web-999.container" ],
      new_command(ssh_user: "deploy").remove_quadlet_file("app-web-999")
  end

  test "container_file_content generates valid INI" do
    content = new_command.container_file_content(
      unit_name: "app-web-999",
      image: "docker.io/dhh/app:999",
      run_args: [ "--name", "app-web-999", "--network", "kamal", "--env", "FOO=bar" ]
    )

    assert_match(/\[Unit\]/, content)
    assert_match(/Description=app-web-999/, content)
    assert_match(/\[Container\]/, content)
    assert_match(/Image=docker\.io\/dhh\/app:999/, content)
    assert_match(/Pull=never/, content)
    assert_match(/ContainerName=app-web-999/, content)
    assert_match(/Network=kamal/, content)
    assert_match(/Environment=FOO=bar/, content)
    assert_match(/\[Service\]/, content)
    assert_match(/Restart=always/, content)
    assert_match(/RestartSec=5s/, content)
    assert_match(/WorkingDirectory=\/root/, content)
    assert_match(/\[Install\]/, content)
    assert_match(/WantedBy=default\.target/, content)
  end

  test "container_file_content with cmd" do
    content = new_command.container_file_content(
      unit_name: "app-jobs-999",
      image: "docker.io/dhh/app:999",
      run_args: [ "--name", "app-jobs-999" ],
      cmd: "bin/jobs"
    )

    assert_match(/Exec=bin\/jobs/, content)
  end

  test "container_file_content resolves relative EnvironmentFile to absolute" do
    content = new_command.container_file_content(
      unit_name: "app-web-999",
      image: "docker.io/dhh/app:999",
      run_args: [ "--name", "app-web-999", "--env-file", ".kamal/apps/app/env/roles/web.env" ]
    )

    assert_match(%r{EnvironmentFile=/root/\.kamal/apps/app/env/roles/web\.env}, content)
    assert_no_match(/EnvironmentFile=\.kamal/, content)
  end

  test "container_file_content preserves absolute EnvironmentFile" do
    content = new_command.container_file_content(
      unit_name: "app-web-999",
      image: "docker.io/dhh/app:999",
      run_args: [ "--name", "app-web-999", "--env-file", "/etc/app/env" ]
    )

    assert_match(%r{EnvironmentFile=/etc/app/env}, content)
  end

  test "container_file_content resolves relative EnvironmentFile for rootless" do
    content = new_command(ssh_user: "deploy").container_file_content(
      unit_name: "app-web-999",
      image: "docker.io/dhh/app:999",
      run_args: [ "--name", "app-web-999", "--env-file", ".kamal/apps/app/env/roles/web.env" ]
    )

    assert_match(%r{EnvironmentFile=\$HOME/\.kamal/apps/app/env/roles/web\.env}, content)
  end

  test "container_file_content without cmd omits Exec" do
    content = new_command.container_file_content(
      unit_name: "app-web-999",
      image: "docker.io/dhh/app:999",
      run_args: [ "--name", "app-web-999" ]
    )

    assert_no_match(/Exec=/, content)
  end

  test "container_file_content section order is Unit, Container, Service, Install" do
    content = new_command.container_file_content(
      unit_name: "app-web-999",
      image: "docker.io/dhh/app:999",
      run_args: []
    )

    unit_pos = content.index("[Unit]")
    container_pos = content.index("[Container]")
    service_pos = content.index("[Service]")
    install_pos = content.index("[Install]")

    assert unit_pos < container_pos
    assert container_pos < service_pos
    assert service_pos < install_pos
  end

  test "container_file_content defaults to Restart=always" do
    content = new_command.container_file_content(
      unit_name: "app-web-999",
      image: "docker.io/dhh/app:999",
      run_args: []
    )

    assert_match(/Restart=always/, content)
  end

  test "container_file_content with restart_policy on-failure" do
    content = new_command.container_file_content(
      unit_name: "kamal-proxy",
      image: "docker.io/basecamp/kamal-proxy:v0.9.0",
      run_args: [],
      restart_policy: "on-failure"
    )

    assert_match(/Restart=on-failure/, content)
    assert_no_match(/Restart=always/, content)
  end

  private
    def new_command(ssh_user: nil)
      config_hash = @config.dup
      config_hash[:ssh] = { "user" => ssh_user } if ssh_user
      KamalPodman::Commands::Quadlet.new(Kamal::Configuration.new(config_hash, version: "999"))
    end
end

class QuadletEnabledTest < ActiveSupport::TestCase
  test "quadlet_enabled? returns false by default" do
    config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
    commander = KamalPodman::Commander.new
    commander.stubs(:config).returns(Kamal::Configuration.new(config, version: "999"))

    assert_not commander.quadlet_enabled?
  end

  test "quadlet_enabled? returns true when x-quadlet is true" do
    config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" },
      "x-quadlet": true
    }
    commander = KamalPodman::Commander.new
    commander.stubs(:config).returns(Kamal::Configuration.new(config, version: "999"))

    assert commander.quadlet_enabled?
  end

  test "quadlet_enabled? returns false when x-quadlet is not true" do
    config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" },
      "x-quadlet": "yes"
    }
    commander = KamalPodman::Commander.new
    commander.stubs(:config).returns(Kamal::Configuration.new(config, version: "999"))

    assert_not commander.quadlet_enabled?
  end

  test "commander exposes quadlet command instance" do
    config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
    commander = KamalPodman::Commander.new
    commander.stubs(:config).returns(Kamal::Configuration.new(config, version: "999"))

    assert_kind_of KamalPodman::Commands::Quadlet, commander.quadlet
  end
end

class QuadletAppStopOverrideTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
    @kamal_config = Kamal::Configuration.new(@config, version: "999")
    @quadlet = KamalPodman::Commands::Quadlet.new(@kamal_config)
  end

  test "stop with version returns systemctl stop when quadlet enabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(true)
    KAMAL.stubs(:quadlet).returns(@quadlet)

    app = Kamal::Commands::App.new(@kamal_config, role: @kamal_config.role(:web), host: "1.1.1.1")
    result = app.stop(version: "999")

    assert_equal [ :systemctl, :stop, "app-web-999.service" ], result
  end

  test "stop without version falls back to original when quadlet enabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(true)
    KAMAL.stubs(:quadlet).returns(@quadlet)

    app = Kamal::Commands::App.new(@kamal_config, role: @kamal_config.role(:web), host: "1.1.1.1")
    result = app.stop.join(" ")

    assert_match(/podman/, result)
  end

  test "stop delegates to original when quadlet disabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(false)

    app = Kamal::Commands::App.new(@kamal_config, role: @kamal_config.role(:web), host: "1.1.1.1")
    result = app.stop(version: "999").join(" ")

    assert_match(/podman/, result)
  end
end
