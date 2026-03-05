# frozen_string_literal: true

Kamal::Commands::Proxy.class_eval do
  alias_method :original_start, :start

  def start
    return original_start unless KAMAL.quadlet_enabled?
    KAMAL.quadlet.start_unit(container_name)
  end

  alias_method :original_stop, :stop

  def stop(name: container_name)
    return original_stop(name: name) unless KAMAL.quadlet_enabled?
    KAMAL.quadlet.stop_unit(name)
  end

  alias_method :original_start_or_run, :start_or_run

  def start_or_run
    return original_start_or_run unless KAMAL.quadlet_enabled?
    KAMAL.quadlet.start_unit(container_name)
  end
end
