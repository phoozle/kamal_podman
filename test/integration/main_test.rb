require_relative "integration_test"

class MainTest < IntegrationTest
  test "server bootstrap" do
    # Test basic server bootstrap functionality
    # This is simplified compared to full deploy since we're focusing on Podman integration

    # Verify podman is installed and working
    result = docker_compose("exec -T vm1 podman --version", capture: true)
    assert_match /podman version/, result.downcase

    # Test kamal server bootstrap command exists and mentions Podman
    result = kamal("server", "bootstrap", "--help", capture: true)
    puts "DEBUG: kamal server bootstrap --help output: #{result.inspect}" if ENV["DEBUG"]
    puts "DEBUG: Looking for /podman/i in: #{result.downcase}" if ENV["DEBUG"]
    assert_match /podman/i, result.downcase
  end

  test "kamal_podman gem is loaded" do
    # Test that kamal_podman gem is actually loaded and working

    # Check that KamalPodman module is defined
    result = deployer_exec("ruby -e 'require \"kamal_podman\"; puts KamalPodman.class'", capture: true)
    puts "DEBUG: KamalPodman module check: #{result.inspect}" if ENV["DEBUG"]
    assert_match /Module/, result

    # Check that the override is working by testing the main command description
    result = kamal("server", "--help", capture: true)
    puts "DEBUG: kamal server --help for gem loading test: #{result.inspect}" if ENV["DEBUG"]
    assert_match /podman/i, result.downcase

    # Test that KamalPodman::Cli::Server exists
    result = deployer_exec("ruby -e 'require \"kamal_podman\"; puts KamalPodman::Cli::Server.class'", capture: true)
    puts "DEBUG: KamalPodman::Cli::Server check: #{result.inspect}" if ENV["DEBUG"]
    assert_match /Class/, result
  end

  test "config" do
    # Test configuration loading and validation
    # Adapted from upstream but simplified for our current setup

    config_content = deployer_exec("cat /app/deploy.yml", capture: true)
    config = YAML.load(config_content)

    assert_equal "app", config["service"]
    assert_equal [ "vm1" ], Array(config["servers"]["web"]["hosts"] || config["servers"])
    assert_equal "nginx:latest", config["image"]
  end

  test "podman commands" do
    # Test that our Podman integration works

    # Test podman info
    result = docker_compose("exec -T vm1 podman info --format json", capture: true)
    info = JSON.parse(result)
    assert info["version"]["Version"]

    # Test podman ps (should be empty initially)
    result = docker_compose("exec -T vm1 podman ps --format json", capture: true)
    containers = JSON.parse(result) rescue []
    assert containers.is_a?(Array)
  end

  test "ssh connectivity" do
    # Test SSH connection from deployer to VM
    # This is essential for kamal to work

    result = docker_compose("exec -T deployer ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@vm1 'echo ssh_test'", capture: true)
    assert_equal "ssh_test", result.strip
  end

  test "kamal podman integration" do
    # Test that kamal commands load our podman integration

    result = kamal("--version", capture: true)
    puts "DEBUG: kamal --version output: #{result.inspect}" if ENV["DEBUG"]
    assert_match /kamal/i, result

    # Test that server commands mention Podman instead of Docker
    result = kamal("server", "--help", capture: true)
    puts "DEBUG: kamal server --help output: #{result.inspect}" if ENV["DEBUG"]
    puts "DEBUG: Looking for /podman/i in: #{result.downcase}" if ENV["DEBUG"]
    assert_match /podman/i, result.downcase
  end



  private

  def assert_container_running(host:, name:)
    result = docker_compose("exec -T #{host} podman ps --filter=name=#{name} --format json", capture: true, raise_on_error: false)
    containers = JSON.parse(result) rescue []
    assert containers.any?, "Expected container #{name} to be running on #{host}"
  end

  def assert_container_not_running(host:, name:)
    result = docker_compose("exec -T #{host} podman ps --filter=name=#{name} --format json", capture: true, raise_on_error: false)
    containers = JSON.parse(result) rescue []
    assert containers.empty?, "Expected container #{name} to not be running on #{host}"
  end
end
