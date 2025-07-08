# frozen_string_literal: true

# Remove the existing KAMAL constant if it exists to avoid redefinition warnings
Object.send(:remove_const, :KAMAL) if defined?(KAMAL)

# Define our Podman-based KAMAL constant
KAMAL = KamalPodman::Commander.new
