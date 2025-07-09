require "bundler/setup"
require "minitest/autorun" # using #stub that take args
require "active_support/testing/stream"
require "debug"
require "mocha/minitest" # using #stubs that can alter returns
require "kamal_podman"
require "kamal"

# Applies to remote commands only.
SSHKit.config.backend = SSHKit::Backend::Printer

class SSHKit::Backend::Printer
  def upload!(local, location, **kwargs)
    local = local.string.inspect if local.respond_to?(:string)
    puts "Uploading #{local} to #{location} on #{host}"
  end
end

# Ensure local commands use the printer backend too.
# See https://github.com/capistrano/sshkit/blob/master/lib/sshkit/dsl.rb#L9
module SSHKit
  module DSL
    def run_locally(&block)
      SSHKit::Backend::Printer.new(SSHKit::Host.new(:local), &block).run
    end
  end
end

class ActiveSupport::TestCase
  include ActiveSupport::Testing::Stream

  private
    def stdouted
      capture(:stdout) { yield }.strip
    end
end
