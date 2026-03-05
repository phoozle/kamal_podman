# frozen_string_literal: true

require "test_helper"

class QuadletAccessoryCommandsTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "user", "password" => "pw" },
      servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" },
      accessories: {
        "mysql" => {
          "image" => "mysql:8.0",
          "host" => "1.1.1.1",
          "port" => "3306:3306",
          "env" => {
            "clear" => { "MYSQL_ROOT_PASSWORD" => "secret" }
          }
        }
      }
    }
    @kamal_config = Kamal::Configuration.new(@config, version: "999")
    @quadlet = KamalPodman::Commands::Quadlet.new(@kamal_config)
  end

  test "start returns systemctl start when quadlet enabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(true)
    KAMAL.stubs(:quadlet).returns(@quadlet)

    accessory = Kamal::Commands::Accessory.new(@kamal_config, name: :mysql)
    result = accessory.start

    assert_equal [ :systemctl, :start, "app-mysql.service" ], result
  end

  test "start falls back to original when quadlet disabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(false)

    accessory = Kamal::Commands::Accessory.new(@kamal_config, name: :mysql)
    result = accessory.start.join(" ")

    assert_match(/podman/, result)
    assert_match(/app-mysql/, result)
  end

  test "stop returns systemctl stop when quadlet enabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(true)
    KAMAL.stubs(:quadlet).returns(@quadlet)

    accessory = Kamal::Commands::Accessory.new(@kamal_config, name: :mysql)
    result = accessory.stop

    assert_equal [ :systemctl, :stop, "app-mysql.service" ], result
  end

  test "stop falls back to original when quadlet disabled" do
    KAMAL.stubs(:quadlet_enabled?).returns(false)

    accessory = Kamal::Commands::Accessory.new(@kamal_config, name: :mysql)
    result = accessory.stop.join(" ")

    assert_match(/podman/, result)
    assert_match(/app-mysql/, result)
  end
end
