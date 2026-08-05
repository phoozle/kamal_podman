require_relative "integration_test"

class DeployTest < IntegrationTest
  test "deploy" do
    version = latest_app_version

    # Deploy the app
    kamal :deploy

    # Verify the app container is running on vm1
    assert_container_running host: :vm1, name: "app-web-#{version}"

    # Verify kamal-proxy is running
    assert_container_running host: :vm1, name: "kamal-proxy"
  end

  # Exercises Kamal's own container lookup rather than querying podman directly. That path
  # runs through `podman ps --filter status=...`, which silently returned nothing when the
  # filter included docker-only states — so a deploy could not see what was already running.
  test "app version sees the running container through kamal's own lookup" do
    version = latest_app_version

    kamal :deploy

    output = kamal :app, :version, capture: true
    assert_match /#{version}/, output
  end

  test "deploy uses podman not docker" do
    output = kamal :deploy, "--verbose", capture: true

    # Every container command should use podman
    assert_match /podman/, output
    # Filter out "docker.io" registry references — those are expected
    filtered = output.gsub("docker.io", "").gsub("host.docker.internal", "")
    assert_no_match(/\bdocker\b/, filtered)
  end
end
