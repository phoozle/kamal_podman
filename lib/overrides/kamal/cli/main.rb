Kamal::Cli::Main.class_eval do
  desc "server", "Bootstrap servers with curl and Podman"
  subcommand "server", KamalPodman::Cli::Server
end
