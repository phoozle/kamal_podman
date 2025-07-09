# Integration Tests - Upstream Alignment Guide

This document explains how kamal_podman's integration tests are maintained in alignment with the upstream Kamal project to ensure consistency and ease of development for contributors working between both codebases.

## Overview

The integration tests in kamal_podman are **directly ported and adapted** from the upstream Kamal project, maintaining identical structure, naming, and execution patterns while adapting the underlying container runtime from Docker to Podman.

## File Structure Alignment

| Upstream Kamal | Our Kamal Podman | Purpose |
|---------------|------------------|---------|
| [`test/integration/integration_test.rb`](https://github.com/basecamp/kamal/blob/main/test/integration/integration_test.rb) | `test/integration/integration_test.rb` | Base test infrastructure class |
| [`test/integration/main_test.rb`](https://github.com/basecamp/kamal/blob/main/test/integration/main_test.rb) | `test/integration/main_test.rb` | Core deployment tests |
| [`test/integration/docker-compose.yml`](https://github.com/basecamp/kamal/blob/main/test/integration/docker-compose.yml) | `test/integration/docker-compose.yml` | Test infrastructure orchestration |
| [`test/integration/docker/`](https://github.com/basecamp/kamal/tree/main/test/integration/docker) | `test/integration/docker/` | Container definitions |

## Test Execution Alignment

### Identical Commands
All test execution commands are **identical** to upstream Kamal:

```bash
# Run all tests (unit + integration)
bin/test

# Run integration tests only
bin/test test/integration/

# Run specific test file  
bin/test test/integration/main_test.rb

# Run specific test method
bin/test test/integration/main_test.rb --name test_config

# Verbose output
bin/test -v

# All minitest options work identically
bin/test --help
```

### Why This Alignment Matters
1. **Developer Familiarity**: Contributors familiar with upstream Kamal can immediately understand and run our tests
2. **Consistent Patterns**: Same debugging approaches, same command patterns
3. **Easy Porting**: New upstream tests can be adapted quickly
4. **Documentation Reuse**: Upstream testing documentation applies to our project

## Test Infrastructure Comparison

### Upstream Kamal Infrastructure
- **Container Runtime**: Docker
- **Orchestration**: Docker Compose
- **Test VMs**: `vm1`, `vm2`, `vm3` 
- **Services**: `deployer`, `shared`, `load_balancer`, `registry`
- **Commands**: `docker ps`, `docker exec`, etc.

### Our Kamal Podman Infrastructure  
- **Container Runtime**: Podman (adapted)
- **Orchestration**: Docker Compose (same)
- **Test VMs**: `vm1` (simplified for initial implementation)
- **Services**: `deployer`, `shared` (simplified)
- **Commands**: `podman ps`, `podman exec`, etc.

## Key Adaptations Made

### 1. Container Commands
```ruby
# Upstream
docker_compose("exec #{host} docker ps --filter=name=#{name}")

# Our adaptation  
docker_compose("exec #{host} podman ps --filter=name=#{name}")
```

### 2. Infrastructure Simplification
- **Upstream**: Full multi-VM setup with load balancer and registry
- **Ours**: Simplified single-VM setup focusing on Podman integration

### 3. Test Focus
- **Upstream**: Full deployment lifecycle testing
- **Ours**: Podman integration and basic deployment functionality

## Reference Links

### Upstream Kamal Integration Tests
- [Integration Test Base Class](https://github.com/basecamp/kamal/blob/main/test/integration/integration_test.rb)
- [Main Integration Tests](https://github.com/basecamp/kamal/blob/main/test/integration/main_test.rb) 
- [Docker Compose Setup](https://github.com/basecamp/kamal/blob/main/test/integration/docker-compose.yml)
- [Test Infrastructure](https://github.com/basecamp/kamal/tree/main/test/integration/docker)
- [CI Workflow](https://github.com/basecamp/kamal/blob/main/.github/workflows/ci.yml)

### Complete Test File List
- [accessory_test.rb](https://github.com/basecamp/kamal/blob/main/test/integration/accessory_test.rb)
- [app_test.rb](https://github.com/basecamp/kamal/blob/main/test/integration/app_test.rb)
- [broken_deploy_test.rb](https://github.com/basecamp/kamal/blob/main/test/integration/broken_deploy_test.rb)
- [lock_test.rb](https://github.com/basecamp/kamal/blob/main/test/integration/lock_test.rb)
- [proxy_test.rb](https://github.com/basecamp/kamal/blob/main/test/integration/proxy_test.rb)

## Adding New Tests

When adding new integration tests:

1. **Check Upstream First**: Look for equivalent tests in upstream Kamal
2. **Maintain Structure**: Use same file names and test method patterns
3. **Adapt for Podman**: Replace Docker commands with Podman equivalents
4. **Keep Execution Identical**: Ensure `bin/test` commands work the same way

## Future Expansion

As we expand our integration test suite, we should port additional test files from upstream:

- [ ] `app_test.rb` - Application lifecycle tests
- [ ] `proxy_test.rb` - Proxy management tests  
- [ ] `accessory_test.rb` - Accessory services tests
- [ ] `lock_test.rb` - Deployment locking tests

Each should follow the same adaptation pattern: maintain structure, adapt commands for Podman.

## Development Workflow

```bash
# Start development
cd test/integration

# Start containers manually for debugging
docker compose up -d

# Run tests against running containers  
bin/test test/integration/main_test.rb -v

# Debug containers
docker compose logs deployer
docker compose exec -it deployer bash

# Cleanup
docker compose down
```

This maintains the exact same development experience as upstream Kamal while providing Podman-specific functionality.