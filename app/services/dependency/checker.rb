require "dependabot/file_fetchers"
require "dependabot/file_parsers"
require "dependabot/update_checkers"
require "dependabot/file_updaters"
require "dependabot/pull_request_creator"

class Dependency::Checker
  PRIVATE_KEY = OpenSSL::PKey::RSA.new(ENV['GITHUB_PRIVATE_KEY'].gsub('\n', "\n")) # convert newlines
  APP_IDENTIFIER = ENV['GITHUB_APP_IDENTIFIER']

  def self.run repository
    Dependency::Checker.new(repository).run
  end

  def initialize repository
    @repository = repository
  end

  def run
    puts "--- Repository name: #{@repository.repo_name} ---"

    payload = {
        iat: Time.now.to_i,
        exp: Time.now.to_i + (10 * 60),
        iss: APP_IDENTIFIER
    }
    jwt = JWT.encode(payload, PRIVATE_KEY, 'RS256')
    client = Octokit::Client.new(bearer_token: jwt)

    installation_token = client.create_app_installation_access_token(@repository.installation_id)[:token]

    if @repository.package_manager.nil?
      repo_client = Octokit::Client.new(bearer_token: installation_token)
      case repo_client.languages(@repository.repo_name).first[0].to_s
      when "JavaScript"
        @repository.update(package_manager: "npm_and_yarn")
      when "Ruby"
        @repository.update(package_manager: "bundler")
      end
    end

    puts "--- Package Manager: #{@repository.package_manager} ---"

    credentials =
      [{
        "type" => "git_source",
        "host" => "github.com",
        "username" => "x-access-token",
        "password" => installation_token
      }]

    source = Dependabot::Source.new(
      provider: "github",
      repo: @repository.repo_name,
      directory: @repository.directory,
      branch: nil
    )

    fetcher = Dependabot::FileFetchers.for_package_manager(@repository.package_manager).
              new(source: source, credentials: credentials)

    files = fetcher.files
    commit = fetcher.commit

    parser = Dependabot::FileParsers.for_package_manager(@repository.package_manager).new(
      dependency_files: files,
      source: source,
      credentials: credentials,
    )

    dependencies = parser.parse

    dependencies.each do |dep|
      checker = Dependabot::UpdateCheckers.for_package_manager(@repository.package_manager).new(
        dependency: dep,
        dependency_files: files,
        credentials: credentials,
      )

      checker.up_to_date?
      checker.can_update?(requirements_to_unlock: :own)
      updated_deps = checker.updated_dependencies(requirements_to_unlock: :own)

      updater = Dependabot::FileUpdaters.for_package_manager(@repository.package_manager).new(
        dependencies: updated_deps,
        dependency_files: files,
        credentials: credentials,
      )

      updated_files = updater.updated_dependency_files

      pr_creator = Dependabot::PullRequestCreator.new(
        source: source,
        base_commit: commit,
        dependencies: updated_deps,
        files: updated_files,
        credentials: credentials,
      )

      pr_creator.create

      puts "--- SUCCESS: Created PR for: #{dep.name} ---"
    rescue e
      puts "--- FAIL: Failed to check dependency: #{dep.name} ---"
      puts "    #{e.message}"
    end
  end
end
