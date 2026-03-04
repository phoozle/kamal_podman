require_relative "integration_test"

class QuadletDeployTest < IntegrationTest
  test "deploy with quadlet creates systemd service" do
    version = latest_app_version
    # Kamal naming: {service}-{role}-{destination}-{version}
    container_name = "app-web-quadlet-#{version}"

    # Deploy using the quadlet destination (x-quadlet: true)
    kamal :deploy, "-d quadlet"

    # Verify the .container file was written to the quadlet directory
    container_file = docker_compose(
      "exec -T vm1 cat /etc/containers/systemd/#{container_name}.container",
      capture: true
    )
    assert_match /\[Unit\]/, container_file
    assert_match /\[Container\]/, container_file
    assert_match /Image=/, container_file
    assert_match /Pull=never/, container_file
    assert_match /ContainerName=#{container_name}/, container_file

    # Verify the systemd service is active
    service_status = docker_compose(
      "exec -T vm1 systemctl is-active #{container_name}.service",
      capture: true
    )
    assert_match /active/, service_status

    # Verify the container is actually running via podman
    assert_container_running host: :vm1, name: container_name

    # Verify kamal-proxy is running (proxy lifecycle is unchanged)
    assert_container_running host: :vm1, name: "kamal-proxy"
  end
end
