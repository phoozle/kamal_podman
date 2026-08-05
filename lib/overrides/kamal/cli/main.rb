# frozen_string_literal: true

# Re-describe the `server` subcommand without swapping the registered class. Kamal::Cli::Base
# #command resolves the running class through Kamal::Cli::Main.subcommand_classes, so it has
# to stay Kamal::Cli::Server — the Podman bootstrap is patched onto that class instead
# (see overrides/kamal/cli/server.rb).
Kamal::Cli::Main.class_eval do
  desc "server", "Bootstrap servers with curl and Podman"
  subcommand "server", Kamal::Cli::Server
  subcommands.uniq!
end
