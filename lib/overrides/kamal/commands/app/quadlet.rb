# frozen_string_literal: true

Kamal::Commands::App.class_eval do
  alias_method :original_stop, :stop

  def stop(version: nil)
    return original_stop(version: version) unless KAMAL.quadlet_enabled?

    if version
      KAMAL.quadlet.stop_unit(container_name(version))
    else
      # No specific version — pipe current container through podman stop (original behavior)
      original_stop(version: version)
    end
  end
end
