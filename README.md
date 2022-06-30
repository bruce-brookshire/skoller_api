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

To generate API Documentation, run `mix hex.docs`

## IEx console on server

- SSH into env
- `cd /opts/api`
- `source ~/scripts/api_vars.sh && iex -S mix`
## Deployment

### Staging
#### Adding a new dev
 - Have new dev generate RSA key pair
 - Connect to staging server
 - Run commands to create user
 - Have new dev add config to .ssh/config file
 -  ```
      Host skoller-prod
       HostName 34.196.63.225
       Port 22
       IdentityFile ~/.ssh/skoller_rsa
       user chris.dierolf
  ```
  ```

        Host skoller-staging
        HostName 54.198.69.2
        Port 22
        IdentityFile ~/.ssh/skoller_rsa
        user chris.dierolf
  ```
- Connect to server `ssh skoller-staging` or `ssh skoller-prod`




## NOTES
- `Skoller.Periods.generate_periods_for_all_schools_for_year()` must be run from the iex console (see IEx console on server) once a year to generate periods for all school for the current year.
- Subscription plans: month, year, premium-vip



