# Kamal - Podman

![kamal-podman](https://github.com/user-attachments/assets/52046e04-9145-48c0-aa80-fd8a0872921e)

## Overview
`kamal_podman` is a Ruby gem designed to integrate the power of Kamal for deployment management with Podman as the container manager. This gem provides an alternative to Docker for those who prefer or require Podman's daemonless architecture and enhanced security features.

Kamal Integration: Kamal Podman extends the functionality of Kamal, a deployment tool from Basecamp, allowing you to deploy your applications using Kamal's commands and configurations.
Podman Utilization: Instead of Docker, this gem uses Podman for managing containers, providing a lightweight, user-space focused container runtime.

## Current State
Please note that Kamal Podman is still under development. Not all features are fully implemented or tested.
Incomplete Features: Some Kamal commands might not translate directly to Podman's API, leading to partial functionality or differing behavior.
Experimental: The gem is in its experimental phase, and you might encounter bugs or unexpected behaviors.

## Installation: 

You can simply drop in this gem to an existing Kamal based project and start deploying with Podman instead. However you will need to run `kamal app remove` and `kamal proxy remove` to avoid any conflicts. Be aware this will completely shutdown and remove your current application.

```
# Gemfile
gem 'kamal_podman', git: 'https://github.com/phoozle/kamal_podman.git', branch: 'master'
```

Usage: Follow Kamal's official documentation for the most part but specify Podman as your container runtime in your configurations.
There will most likely be some differences in the commands due to the inherit nature of how Podman does things compared to Docker and those differences I will document below as I find them.

## Roadmap
- Complete integration of all Kamal commands with Podman.
- Systemd integration
- Enhance error handling and logging.
- Increase test coverage for better reliability.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/phoozle/kamal_podman.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Kamal::Podman project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/kamal-podman/blob/master/CODE_OF_CONDUCT.md).
