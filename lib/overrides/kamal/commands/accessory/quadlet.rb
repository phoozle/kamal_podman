# frozen_string_literal: true

Kamal::Commands::Accessory.class_eval do
  alias_method :original_start, :start

  def start
    return original_start unless KAMAL.quadlet_enabled?
    KAMAL.quadlet.start_unit(service_name)
  end

  alias_method :original_stop, :stop

  def stop
    return original_stop unless KAMAL.quadlet_enabled?
    KAMAL.quadlet.stop_unit(service_name)
  end
end
