# Integration Tests - Upstream Alignment Guide

This document explains how kamal_podman's integration tests are maintained in alignment with the upstream Kamal project to ensure consistency and ease of development for contributors working between both codebases.

## Overview

The integration tests in kamal_podman are directly ported and adapted from the upstream Kamal project, maintaining identical structure, naming, and execution patterns while adapting the underlying container runtime from Docker to Podman.

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
```

## Test Infrastructure Comparison between main Kamal gem

### Upstream Kamal Infrastructure
- **Container Runtime**: Docker
- **Orchestration**: Docker Compose
- **Test VMs**: `vm1`, `vm2`, `vm3`
- **Services**: `deployer`, `shared`, `load_balancer`, `registry`
- **Commands**: `docker ps`, `docker exec`, etc.

### Our Kamal Podman Infrastructure
- **Container Runtime**: Podman
- **Orchestration**: Docker Compose (same)
- **Test VMs**: `vm1` (reduced)
- **Services**: `deployer`, `shared` (simplified)
- **Commands**: `podman ps`, `podman exec`, etc.

## Reference Links

### Upstream Kamal Integration Tests replicated
- [Integration Test Base Class](https://github.com/basecamp/kamal/blob/main/test/integration/integration_test.rb)
- [Main Integration Tests](https://github.com/basecamp/kamal/blob/main/test/integration/main_test.rb)
