# CLAUDE.md — kamal_podman

## Project Overview

**kamal_podman** is a Ruby gem that extends [Kamal](https://kamal-deploy.org) (Basecamp's container deployment tool) to use **Podman** instead of Docker as the container runtime. It works by monkey-patching Kamal's internals at load time, replacing all `docker` CLI calls with `podman` equivalents.

- **Gem name**: `kamal_podman`
- **Current version**: 0.1.0
- **Pinned Kamal version**: 2.10.1 (exact pin — any Kamal update may break overrides)
- **License**: MIT
- **Ruby**: >= 3.0.0

## Architecture

### Core Mechanism: Monkey-Patching via `class_eval`

The gem's architecture revolves around reopening Kamal's classes at runtime:

1. `lib/kamal_podman.rb` loads the `kamal` gem first (all Kamal code)
2. Zeitwerk autoloads `KamalPodman::*` classes, **ignoring** `lib/overrides/`
3. `Kamal::Cli` namespace is **eager-loaded** so all classes exist before patching
4. All files in `lib/overrides/` are loaded via `Dir.glob` + `load()` — these use `class_eval` to patch Kamal classes
5. `override.rb` replaces the global `KAMAL` constant with `KamalPodman::Commander`

**Load order matters.** Kamal must be fully loaded before overrides are applied.

### Override Pattern

Every override file follows this pattern:

```ruby
Kamal::Commands::SomeClass.class_eval do
  def docker(*args)
    podman(*args)
  end
end
```

The foundational override is `overrides/kamal/commands/base.rb`, which:
- Adds a `podman(*args)` method to `Kamal::Commands::Base`
- Makes `docker()` raise an error (to catch missed overrides)
- Overrides `container_id_for` to use podman

### Key Classes

| Class | Purpose |
|---|---|
| `KamalPodman::Commander` | Extends `Kamal::Commander`, returns Podman-aware builder/commands |
| `KamalPodman::Commands::Podman` | Podman system commands (`installed?`, `running?`, `create_network`) |
| `KamalPodman::Commands::Builder` | Podman-based builder (local builds only, no buildx) |
| `KamalPodman::Commands::Builder::Local` | `podman build` + `podman push` (stubs out buildx lifecycle) |
| `KamalPodman::Cli::Server` | Podman-aware server bootstrap (checks for Podman, not Docker) |

### Podman-Specific Differences from Docker

- **Registry**: Podman requires explicit registry prefixes (`docker.io/`) — Docker defaults to Docker Hub implicitly
- **Builder**: No buildx/buildkit equivalent — uses `podman build` + `podman push` directly
- **Prune**: Commands rewritten to use `podman image ls`, `podman rmi`, `podman ps`, `podman rm`
- **Network**: Creates `kamal` network via `podman network create`
- **No daemon**: Podman is daemonless — `running?` checks `podman version` instead of daemon status

## Directory Structure

```
lib/
  kamal_podman.rb              # Entry point — loads Kamal, sets up Zeitwerk, applies overrides
  kamal_podman/
    version.rb                 # VERSION constant
    override.rb                # Replaces global KAMAL constant
    commander.rb               # Custom Commander subclass
    cli/
      server.rb                # Podman-aware server bootstrap
    commands/
      podman.rb                # Podman system commands
      builder.rb               # Builder orchestrator
      builder/
        local.rb               # Local build implementation
  overrides/                   # NOT autoloaded by Zeitwerk — loaded manually via Dir.glob
    kamal/
      cli/
        main.rb                # Replaces server subcommand
      commands/
        base.rb                # Foundation: adds podman(), disables docker()
        app.rb                 # docker->podman for App
        app/
          containers.rb        # docker->podman for Containers
          proxy.rb             # docker->podman for Proxy
          assets.rb            # docker->podman for Assets
          images.rb            # docker->podman for Images
        proxy.rb               # docker->podman for Proxy commands
        registry.rb            # docker->podman for Registry
        prune.rb               # Rewrites prune logic for Podman
      configuration/
        registry.rb            # Default registry = docker.io
        configuration.rb       # Proxy image with docker.io prefix
```

## Development

### Commands

```bash
bin/setup          # Install dependencies
bin/test           # Run tests
bin/console        # Interactive console (IRB with gem loaded)
bundle exec rubocop --parallel   # Lint
rake               # Run tests + rubocop (default task)
```

### Testing

- **Framework**: Minitest + `ActiveSupport::TestCase`
- **Mocking**: Mocha
- **Test runner**: `bin/test` (uses `rails/plugin/test`)
- **SSHKit backend**: Tests use `SSHKit::Backend::Printer` (prints commands to stdout, does not execute over SSH)
- **Fixtures**: `test/fixtures/deploy_simple.yml`

#### Unit Tests (`test/`)

Verify that Kamal CLI commands produce `podman` output instead of `docker`.

#### Integration Tests (`test/integration/`)

Use Docker Compose to spin up 4 services:
- **deployer**: Ruby 3.4 container with Podman installed, runs kamal commands
- **vm1**: Ubuntu 24.04 container with Podman + SSH, acts as deployment target
- **registry**: Local HTTP registry (registry:2) with htpasswd auth on port 5000
- **shared**: Generates SSH keys and TLS certs

Run from host (not from inside containers):
```bash
ruby -Itest test/integration/main_test.rb test/integration/deploy_test.rb
```

The test framework's `setup` hook handles `docker compose up/down` automatically.

**Podman-in-Docker quirks** (relevant for integration test debugging):
- vm1 needs `cgroup_manager = "cgroupfs"`, `pids_limit = 0`, `events_logger = "file"` in containers.conf
- kamal-proxy needs `cap-add: NET_BIND_SERVICE` in deploy.yml (Podman doesn't grant this by default unlike Docker)
- Registry must be configured as insecure (`insecure = true`) in both deployer and vm1

### CI

GitHub Actions (`.github/workflows/main.yml`):
- Triggers: push to `main`, PRs, manual dispatch
- Ruby 3.4 only
- Steps: checkout → setup Ruby → RuboCop → `bin/test`

## Coding Conventions

- **Style**: `rubocop-rails-omakase` (Basecamp's opinionated RuboCop config)
- **Frozen string literals**: Used in main library files; not consistently applied in overrides
- **Naming**: Standard Ruby — `snake_case` methods, `CamelCase` classes
- **Override files**: Keep minimal — typically 3–5 lines of actual code per file
- **Test style**: Minitest assertions, `ActiveSupport::TestCase` base, mocha stubs

## Guidelines for Contributors

### Adding Support for a New Kamal Command

1. Create an override file at `lib/overrides/kamal/commands/<name>.rb`
2. Use `class_eval` to reopen the Kamal class and override `docker` → `podman`
3. If the command has Podman-specific syntax differences (like prune), rewrite the methods entirely
4. Add tests in `test/` to verify `podman` appears in output and `docker` does not

### Upgrading the Pinned Kamal Version

This is the highest-risk change. When Kamal releases a new version:

1. Update the pin in `kamal_podman.gemspec`
2. Review Kamal's changelog and diff for changes to **any class that has an override**
3. Check for new commands/classes that need docker→podman overrides
4. Check for changes in method signatures that would break existing overrides
5. Run full test suite — unit AND integration
6. Pay special attention to `Kamal::Commands::Base`, `Kamal::Commands::Prune`, and `Kamal::Configuration`

### Common Pitfalls

- **Load order**: Never `require` override files — they must be loaded via `Dir.glob` + `load()` after Zeitwerk setup
- **Missing overrides**: If a Kamal class calls `docker()` without an override, `Kamal::Commands::Base#docker` will raise an error — this is intentional, to catch unpatched code paths
- **Registry prefixes**: Podman needs explicit `docker.io/` for Docker Hub images — always ensure image references include the registry
- **No buildx**: Podman doesn't have Docker buildx — `create`, `inspect_builder`, and `remove` are stubs. Only local single-arch builds are currently supported
