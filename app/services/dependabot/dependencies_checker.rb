require "dependabot/file_fetchers"
require "dependabot/file_parsers"
require "dependabot/update_checkers"
require "dependabot/file_updaters"
require "dependabot/pull_request_creator"

class DependenciesChecker
  def run
    credentials =
      [{
        "type" => "git_source",
        "host" => "github.com",
        "username" => "x-access-token",
        "password" => "a-github-access-token"
      }]

    # Full name of the GitHub repo you want to create pull requests for.
    repo_name = "github-account/github-repo"

    # Directory where the base dependency files are.
    directory = "/"

    # Name of the dependency you'd like to update. (Alternatively, you could easily
    # modify this script to loop through all the dependencies returned by
    # `parser.parse`.)
    dependency_name = "rails"

    # Name of the package manager you'd like to do the update for. Options are:
    # - bundler
    # - pip (includes pipenv)
    # - npm_and_yarn
    # - maven
    # - gradle
    # - cargo
    # - hex
    # - composer
    # - nuget
    # - dep
    # - elm-package
    # - submodules
    # - docker
    # - terraform
    package_manager = "npm_and_yarn"

    source = Dependabot::Source.new(
      provider: "github",
      repo: repo_name,
      directory: directory,
      branch: nil
    )

    ##############################
    # Fetch the dependency files #
    ##############################
    fetcher = Dependabot::FileFetchers.for_package_manager(package_manager).
              new(source: source, credentials: credentials)

    files = fetcher.files
    commit = fetcher.commit

    ##############################
    # Parse the dependency files #
    ##############################
    parser = Dependabot::FileParsers.for_package_manager(package_manager).new(
      dependency_files: files,
      source: source,
      credentials: credentials,
    )

    dependencies = parser.parse
    dep = dependencies.find { |d| d.name == dependency_name }

    #########################################
    # Get update details for the dependency #
    #########################################
    checker = Dependabot::UpdateCheckers.for_package_manager(package_manager).new(
      dependency: dep,
      dependency_files: files,
      credentials: credentials,
    )

    checker.up_to_date?
    checker.can_update?(requirements_to_unlock: :own)
    updated_deps = checker.updated_dependencies(requirements_to_unlock: :own)

    #####################################
    # Generate updated dependency files #
    #####################################
    updater = Dependabot::FileUpdaters.for_package_manager(package_manager).new(
      dependencies: updated_deps,
      dependency_files: files,
      credentials: credentials,
    )

    updated_files = updater.updated_dependency_files

    ########################################
    # Create a pull request for the update #
    ########################################
    pr_creator = Dependabot::PullRequestCreator.new(
      source: source,
      base_commit: commit,
      dependencies: updated_deps,
      files: updated_files,
      credentials: credentials,
    )
    pr_creator.create
  end
end
