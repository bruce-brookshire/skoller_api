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

To start your Phoenix server:
  * `source` the env file
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Documentation

Check the [`wiki`](https://github.com/classnavapp/classnav_api/wiki) for high level business logic documentation.

To generate API Documentation, run `mix hex.docs`
