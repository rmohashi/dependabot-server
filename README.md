# Dependabot-Server

Repository created for testing the [dependabot-core](https://github.com/dependabot/dependabot-core) project.

## Setup

1. Run `bundle install` to install de dependencies;
2. If your repository uses a language that is not ruby, run the commands below according to your project:
    - JS (Yarn): `cd "$(bundle show dependabot-core)/helpers/yarn" && yarn install && cd -`
    - JS (npm): `cd "$(bundle show dependabot-core)/helpers/npm" && yarn install && cd -`
    - Python: `cd "$(bundle show dependabot-core)/helpers/python" && pyenv exec pip install -r requirements.txt && pyenv local 2.7.15 && pyenv exec pip install -r requirements.txt && pyenv local --unset && cd -`
    - PHP: `cd "$(bundle show dependabot-core)/helpers/php" && composer install && cd -`
    - Elixir: `cd "$(bundle show dependabot-core)/helpers/elixir" && mix deps.get && cd -`
3. Run `rake db:create db:migrate` to set the database;

## Run

- Run `rails server` to start the server;
- If you want to redirect the webhooks, you shoud use the [smee](https://smee.io/) service;
- To run the service that will check for updates, run:

    ```bash
    rake dependency:check_for_updates
    ```
