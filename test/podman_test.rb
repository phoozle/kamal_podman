require "test_helper"

class PodmanTest < ActiveSupport::TestCase
  test "push" do
    with_build_directory do |build_directory|
      Kamal::Commands::Hook.any_instance.stubs(:hook_exists?).returns(true)
      hook_variables = { version: 999, service_version: "app@999", hosts: "1.1.1.1,1.1.1.2,1.1.1.3,1.1.1.4", command: "build", subcommand: "push" }

      SSHKit::Backend::Abstract.any_instance.expects(:capture_with_info)
        .with(:git, "-C", anything, :"rev-parse", :HEAD)
        .returns(Kamal::Git.revision)

      SSHKit::Backend::Abstract.any_instance.expects(:capture_with_info)
        .with(:git, "-C", anything, :status, "--porcelain")
        .returns("")

      run_command("push", "--verbose").tap do |output|
        assert_match /podman/, output
        assert_no_match /docker\s/, output
      end
    end
  end

  private

  def run_command(*command, fixture: :simple)
    stdouted { Kamal::Cli::Build.start([ *command, "-c", "test/fixtures/deploy_#{fixture}.yml" ]) }
  end

  def with_build_directory
    build_directory = File.join Dir.tmpdir, "kamal-clones", "app-#{pwd_sha}", "kamal_podman"
    FileUtils.mkdir_p build_directory
    FileUtils.touch File.join build_directory, "Dockerfile"
    yield build_directory + "/"
  ensure
    FileUtils.rm_rf build_directory
  end

  def pwd_sha
    Digest::SHA256.hexdigest(Dir.pwd)[0..12]
  end
end
