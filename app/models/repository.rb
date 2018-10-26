class Repository < ApplicationRecord
  VALID_PACKAGE_MANAGERS = [
    "bundler",
    "pip",
    "npm_and_yarn",
    "maven",
    "gradle",
    "cargo",
    "hex",
    "composer",
    "nuget",
    "dep",
    "elm-package",
    "submodules",
    "docker",
    "terraform",
    nil
  ].freeze

  validates :package_manager, inclusion: { in: VALID_PACKAGE_MANAGERS }
  validates :installation_id, presence: true
  validates :repo_name, presence: true
  validates :directory, presence: true
end
