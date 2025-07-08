require "net/http"
require "test_helper"

class IntegrationTest < ActiveSupport::TestCase
  setup do
    ENV["TEST_ID"] = SecureRandom.hex
    docker_compose "up --build -d"
    wait_for_healthy
    setup_deployer
    @app = "app"
  end

  teardown do
    if !passed? && ENV["DEBUG_CONTAINER_LOGS"]
      [ :deployer, :vm1, :shared ].each do |container|
        puts
        puts "Logs for #{container}:"
        docker_compose :logs, container
      end
    end
    docker_compose "down -t 1"
  end

  private

  def docker_compose(*commands, capture: false, raise_on_error: true)
    command = "TEST_ID=#{ENV["TEST_ID"]} docker compose #{commands.join(" ")}"
    succeeded = false
    if capture || !ENV["DEBUG"]
      result = stdouted { stderred { succeeded = system("cd test/integration && #{command}") } }
    else
      succeeded = system("cd test/integration && #{command}")
    end

    raise "Command `#{command}` failed with error code `#{$?}`, and output:\n#{result}" if !succeeded && raise_on_error
    result
  end

  def deployer_exec(*commands, workdir: nil, **options)
    workdir ||= "/#{@app}"
    docker_compose("exec -T --workdir #{workdir} deployer #{commands.join(" ")}", **options)
  end

  def kamal(*commands, **options)
    deployer_exec(:kamal, *commands, **options)
  end

  def latest_app_version
    deployer_exec("git rev-parse HEAD", capture: true, workdir: "/#{@app}")
  end

  def wait_for_healthy(timeout: 90)
    # Add initial delay to allow Docker to stabilize container reporting
    sleep 2

    timeout_at = Time.now + timeout
    check_count = 0

    while true
      check_count += 1
      result = docker_compose("ps -a | tail -n +2 | grep -v '(healthy)' | wc -l", capture: true, raise_on_error: false)

      puts "Health check #{check_count}: #{result.strip} containers not healthy" if ENV["DEBUG"]

      break if result.strip == "0"

      if timeout_at < Time.now
        puts "Health check failed after #{timeout} seconds. Container status:"
        all_containers = docker_compose("ps -a", capture: true, raise_on_error: false)
        puts all_containers

        unhealthy_containers = docker_compose("ps -a | tail -n +2 | grep -v '(healthy)'", capture: true, raise_on_error: false)
        puts "Unhealthy containers:"
        puts unhealthy_containers

        raise "Container not healthy after #{timeout} seconds"
      end

      sleep 0.3
    end

    puts "All containers healthy after #{check_count} checks" if ENV["DEBUG"]
  end

  def setup_deployer
    deployer_exec("./setup.sh", workdir: "/") unless $DEPLOYER_SETUP
    $DEPLOYER_SETUP = true
  end

  def assert_container_running(host:, name:)
    assert container_running?(host: host, name: name)
  end

  def assert_container_not_running(host:, name:)
    assert_not container_running?(host: host, name: name)
  end

  def container_running?(host:, name:)
    docker_compose("exec #{host} podman ps --filter=name=#{name} | tail -n+2", capture: true).strip.present?
  end

  def stderred
    capture(:stderr) { yield }
  end

  def stdouted
    capture(:stdout) { yield }
  end

  def app_host(app = @app)
    case app
    when "app"
      "127.0.0.1"
    else
      "localhost"
    end
  end
end
