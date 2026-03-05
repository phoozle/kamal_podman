# frozen_string_literal: true

require "test_helper"

class QuadletProxyCommandsTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }
    @kamal_config = Kamal::Configuration.new(@config, version: "999")
    @quadlet = KamalPodman::Commands::Quadlet.new(@kamal_config)
  end

  test "start returns systemctl start when quadlet enabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(true)
    KAMAL.stubs(:quadlet).returns(@quadlet)

    proxy = Kamal::Commands::Proxy.new(@kamal_config, host: "1.1.1.1")
    result = proxy.start

    assert_equal [ :systemctl, :start, "kamal-proxy.service" ], result
  end

  test "start falls back to original when quadlet disabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(false)

    proxy = Kamal::Commands::Proxy.new(@kamal_config, host: "1.1.1.1")
    result = proxy.start.join(" ")

    assert_match(/podman/, result)
    assert_match(/kamal-proxy/, result)
  end

  test "stop returns systemctl stop when quadlet enabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(true)
    KAMAL.stubs(:quadlet).returns(@quadlet)

    proxy = Kamal::Commands::Proxy.new(@kamal_config, host: "1.1.1.1")
    result = proxy.stop

    assert_equal [ :systemctl, :stop, "kamal-proxy.service" ], result
  end

  test "stop with custom name returns systemctl stop for that name" do
    KAMAL.stubs(:quadlet_enabled?).returns(true)
    KAMAL.stubs(:quadlet).returns(@quadlet)

    proxy = Kamal::Commands::Proxy.new(@kamal_config, host: "1.1.1.1")
    result = proxy.stop(name: "custom-proxy")

    assert_equal [ :systemctl, :stop, "custom-proxy.service" ], result
  end

  test "stop falls back to original when quadlet disabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(false)

    proxy = Kamal::Commands::Proxy.new(@kamal_config, host: "1.1.1.1")
    result = proxy.stop.join(" ")

    assert_match(/podman/, result)
  end

  test "start_or_run returns systemctl start when quadlet enabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(true)
    KAMAL.stubs(:quadlet).returns(@quadlet)

    proxy = Kamal::Commands::Proxy.new(@kamal_config, host: "1.1.1.1")
    result = proxy.start_or_run

    assert_equal [ :systemctl, :start, "kamal-proxy.service" ], result
  end

  test "start_or_run falls back to original when quadlet disabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(false)

    proxy = Kamal::Commands::Proxy.new(@kamal_config, host: "1.1.1.1")
    result = proxy.start_or_run.join(" ")

    assert_match(/podman/, result)
  end
end
