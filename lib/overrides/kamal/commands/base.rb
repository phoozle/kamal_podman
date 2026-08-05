# frozen_string_literal: true

Kamal::Commands::Base.class_eval do
  def docker(*args)
    podman(*args)
  end

  def podman(*args)
    args.compact.unshift :podman
  end
end
