# frozen_string_literal: true

module KamalPodman::Commands::Quadlet::ArgParser
  # Translates a podman-run argument array into Quadlet [Container] directives.
  # Input: the args portion of [:podman, :run, *args] — everything after :run.
  # Returns an array of "Key=Value" strings for the [Container] section.
  def self.parse(run_args)
    directives = []
    args = run_args.map(&:to_s)
    i = 0

    while i < args.length
      case args[i]
      when "--name"
        directives << "ContainerName=#{args[i + 1]}"
        i += 2
      when "--network"
        directives << "Network=#{args[i + 1]}"
        i += 2
      when "--env", "-e"
        directives << "Environment=#{args[i + 1]}"
        i += 2
      when "--env-file"
        directives << "EnvironmentFile=#{args[i + 1]}"
        i += 2
      when "--volume", "-v"
        directives << "Volume=#{args[i + 1]}"
        i += 2
      when "--publish", "-p"
        directives << "PublishPort=#{args[i + 1]}"
        i += 2
      when "--label", "-l"
        directives << "Label=#{args[i + 1]}"
        i += 2
      when "--log-opt"
        directives << "PodmanArgs=--log-opt #{args[i + 1]}"
        i += 2
      when "--log-driver"
        directives << "LogDriver=#{args[i + 1]}"
        i += 2
      when "--hostname"
        directives << "HostName=#{args[i + 1]}"
        i += 2
      when "--detach"
        i += 1
      when "--restart"
        i += 2
      when /\A--restart[= ].+/
        i += 1
      when /\A--(.+)=(.+)\z/
        directives << "PodmanArgs=#{args[i]}"
        i += 1
      when /\A--/
        if i + 1 < args.length && !args[i + 1].start_with?("-")
          directives << "PodmanArgs=#{args[i]} #{args[i + 1]}"
          i += 2
        else
          directives << "PodmanArgs=#{args[i]}"
          i += 1
        end
      else
        # Positional arg (image name or command) — skip, handled separately
        i += 1
      end
    end

    directives
  end
end
