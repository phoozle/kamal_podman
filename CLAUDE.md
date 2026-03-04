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

### Override Architecture: Two Layers

**Layer 1 — Binary swap** (`overrides/kamal/commands/base.rb`):
Overrides `docker()` on `Kamal::Commands::Base` to delegate to `podman()`. All subclasses inherit this automatically via Ruby method resolution — no per-class overrides needed for commands where the only difference is `docker` → `podman`.

```ruby
Kamal::Commands::Base.class_eval do
  def docker(*args)
    podman(*args)        # Layer 1: binary swap, inherited by all subclasses
  end

  def podman(*args)
    args.compact.unshift :podman
  end
end
```

**Layer 2 — Method-level overrides** (remaining files in `overrides/`):
For commands where Podman's syntax genuinely differs from Docker, individual methods are overridden on the specific class. Only add a Layer 2 override when the command flags, output format, or behavior differs — not just the binary name.

| Override file | Why it exists |
|---|---|
| `commands/prune.rb` | Podman has no `docker image prune --filter`; rewrites to `podman image ls` + shell piping |
| `commands/app/logging.rb` | Podman `logs` needs `2>&1` and different flag handling |
| `configuration/registry.rb` | Podman requires explicit `docker.io/` prefix (Docker assumes it) |
| `configuration/proxy/boot.rb` | Same `docker.io/` prefix for kamal-proxy image |
| `cli/main.rb` | Replaces server bootstrap to check for Podman, not Docker |

**Safety net:** `test/auto_discovery_test.rb` dynamically iterates all `Kamal::Commands::Base` subclasses and verifies `docker()` returns a podman command. This catches any new Kamal class added in a future version that doesn't work with the base swap.

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
        base.rb                # Layer 1: docker()→podman() + container_id_for
        app/
          logging.rb           # Layer 2: Podman-specific logs/follow_logs
        prune.rb               # Layer 2: Podman-specific prune commands
      configuration/
        registry.rb            # Default registry = docker.io
        proxy/
          boot.rb              # Proxy image with docker.io prefix
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

### When a New Kamal Command is Added

If the command uses `docker()` internally (most do), it automatically gets the `podman` swap via Layer 1 — **no override file needed**. The auto-discovery test verifies this.

Only add a Layer 2 override if the command has Podman-specific syntax differences:
1. Create an override file at `lib/overrides/kamal/commands/<name>.rb`
2. Use `class_eval` to reopen the Kamal class and override only the methods that differ
3. Add tests in `test/` to verify the exact command output

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
- **Auto-discovery test**: `test/auto_discovery_test.rb` catches any `Kamal::Commands::Base` subclass where `docker()` doesn't return a podman command — run this after Kamal upgrades
- **Registry prefixes**: Podman needs explicit `docker.io/` for Docker Hub images — always ensure image references include the registry
- **No buildx**: Podman doesn't have Docker buildx — `create`, `inspect_builder`, and `remove` are stubs. Only local single-arch builds are currently supported
