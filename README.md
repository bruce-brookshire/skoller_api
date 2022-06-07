# Skoller

## Installation

File Conversion setup
  * install ImageMagick 6
  * install LibreOffice 5.3.7.2
  * Place `soffice_pdf.sh` in your path.

API Dependencies
   * Run `mix deps.get`
   * Get API vars
   * Create and migrate your database with `mix ecto.create && mix ecto.migrate`

## Running

### DevContainer Setup (optional - VSCode Only)
DevContainer setups allow you to skip all of the ASDF versioning, NPM NVM mumbojumbo and get right into development.

Check the `.devcontainer/docker-compose.yml`file line 39 (ports) and line 21 (ports). If you have multiple devcontainers or docker instances using these ports, update them to unused ports
Open the command palatte and select `rebuild in container`
Run `sudo chown -R vscode:vscode _build .elixir_ls`so the devcontainer has the access it needs to do its thing
`mix deps.get` `mix ecto.create` `mix ecto.migrate` and if applicable run seeds.

To start your Phoenix server:
  * `source` the env file
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Documentation

Check the [`wiki`](https://github.com/classnavapp/classnav_api/wiki) for high level business logic documentation.

To generate API Documentation, run `mix hex.docs`


