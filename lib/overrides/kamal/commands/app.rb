# frozen_string_literal: true

# Docker treats "restarting" as an active container state; Podman has no such state and
# rejects the filter outright:
#
#   $ podman ps --filter status=restarting
#   Error: unknown container state: restarting: invalid argument
#
# The error goes to stderr, so `current_running_container_id` and `current_running_version`
# silently return empty instead of failing — which reads to Kamal as "nothing is running".
#
# Constants assigned inside a class_eval block land in the block's lexical scope, not the
# receiver, so this has to go through const_set.
Kamal::Commands::App.send(:remove_const, :ACTIVE_DOCKER_STATUSES)
Kamal::Commands::App.const_set(:ACTIVE_DOCKER_STATUSES, [ :running ].freeze)
