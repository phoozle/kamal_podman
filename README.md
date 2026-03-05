# Kamal - Podman

![kamal-podman](https://github.com/user-attachments/assets/52046e04-9145-48c0-aa80-fd8a0872921e)

## Overview
`kamal_podman` is a Ruby gem designed to integrate the power of Kamal for deployment management with Podman as the container manager. This gem provides an alternative to Docker for those who prefer or require Podman's daemonless architecture and enhanced security features.

Kamal Integration: Kamal Podman extends the functionality of Kamal, a deployment tool from Basecamp, allowing you to deploy your applications using Kamal's commands and configurations.
Podman Utilization: Instead of Docker, this gem uses Podman for managing containers, providing a lightweight, user-space focused container runtime.

## "Stop Using Docker. Use Open Source Instead" - DevOps Toolbox
[![YouTube Video](https://img.youtube.com/vi/Z5uBcczJxUY/0.jpg)](https://www.youtube.com/watch?v=Z5uBcczJxUY)

## Current State
Please note that Kamal Podman is still under development. Not all features are fully implemented or tested.
Incomplete Features: Some Kamal commands might not translate directly to Podman's API, leading to partial functionality or differing behavior.
Experimental: The gem is in its experimental phase, and you might encounter bugs or unexpected behaviors.

Kamal base version: `2.10.1`

## Installation

You can simply drop in this gem to an existing Kamal based project and start deploying with Podman instead. However you will need to run `kamal app remove` and `kamal proxy remove` to avoid any conflicts. Be aware this will completely shutdown and remove your current application.

This gem installs a `kamal-podman` executable so it won't conflict with the standard `kamal` command if you have both gems installed.

```
# Gemfile
gem 'kamal_podman', git: 'https://github.com/phoozle/kamal_podman.git', branch: 'main'
```

## Usage
Use `kamal-podman` wherever you would normally use `kamal`:

```bash
kamal-podman deploy
kamal-podman setup
kamal-podman app logs
```

Follow [Kamal's](https://kamal-deploy.org) official documentation for the most part.
There will be some differences in the commands available due to the inherent nature of how Podman does things.

## Systemd Integration (Quadlet)

Kamal Podman supports optional systemd integration via [Podman Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html). When enabled, app, proxy, and accessory containers are managed as systemd services instead of plain `podman run` processes. This provides:

- Automatic container restart on failure or reboot
- Proper process lifecycle management via systemd
- Integration with `journalctl` for logging
- Rootless support with `loginctl enable-linger`

### Enabling Quadlet

Add `x-quadlet: true` to your `deploy.yml`:

```yaml
x-quadlet: true

service: myapp
image: myuser/myapp
servers:
  - 192.168.1.1
```

Without this flag, kamal_podman uses traditional `podman run/stop/start` commands — the default behavior is unchanged.

### How It Works

When Quadlet is enabled:
- `kamal deploy` writes `.container` unit files to the Podman Quadlet directory and starts them via `systemctl`
- `kamal proxy boot` manages kamal-proxy as a systemd service
- Accessories (`kamal accessory boot`) are also systemd-managed
- Old container unit files are automatically cleaned up during deploys
- For rootless setups (non-root SSH user), `kamal server bootstrap` runs `loginctl enable-linger` so services survive SSH disconnection

## Roadmap
- Enhance error handling and logging.
- Increase test coverage for better reliability.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `./bin/test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Running Tests

```bash
# Run unit tests
bin/test

# Run integration tests (requires Docker/Colima)
ruby -Itest test/integration/main_test.rb test/integration/deploy_test.rb

# Run Quadlet integration test
ruby -Itest test/integration/main_test.rb test/integration/quadlet_deploy_test.rb
```

### Integration Tests

Integration tests verify that kamal_podman works correctly with real Podman containers, including a full E2E deploy. They use Docker Compose to orchestrate:
- A **deployer** (Ruby 3.4 + Podman) that builds/pushes images and runs kamal
- A **vm1** (Ubuntu 24.04 + Podman + SSH) as the deployment target
- A local **registry** for image storage (no Docker Hub dependency)

The deploy test builds an app image, pushes to the local registry, deploys via `kamal deploy`, and verifies both the app container and kamal-proxy are running on vm1 — all using Podman, not Docker.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/phoozle/kamal_podman.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Kamal::Podman project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/phoozle/kamal-podman/blob/main/CODE_OF_CONDUCT.md).
