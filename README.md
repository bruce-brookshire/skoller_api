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

To generate API Documentation, run `mix hex.docs`

## IEx console on server

- SSH into env
- `cd /opts/api`
- `source ~/scripts/api_vars.sh && iex -S mix`
## Deployment
### Adding a new dev
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

      Host skoller-staging
        HostName 54.198.69.2
        Port 22
        IdentityFile ~/.ssh/skoller_rsa
        user chris.dierolf
  ```
- Connect to server `ssh skoller-staging` or `ssh skoller-prod`
- Run the following slew of commands (replacing obvious fields)
- `sudo useradd -c "New User” -s /bin/bash -m new.user`
- `echo "password" | sudo tee ~new.user/.password`
- `sudo chown new.user:new.user ~new.user/.password`
- `sudo chmod 600 ~new.user/.password`
- `PASSWORD=$(sudo cat ~new.user/.password)`
- `echo "new.user:$PASSWORD" | sudo chpasswd`
- `sudo usermod -a -G sudo new.user`
- `sudo mkdir ~new.user/.ssh`
- `sudo chmod 700 ~new.user/.ssh`
- `sudo touch ~new.user/.ssh/authorized_keys`
- `echo "<new.user's public ssh key”`
- `sudo chmod 600 ~new.user/.ssh/authorized_keys`
- `sudo chown -R new.user:new.user ~new.user/.ssh/`
- The new dev should be able to ssh into the environment
- Repeat for the other environment

### Database Access

You can either SSH into ec2 instance for the desired environment and alias the following:
#### Staging
`alias stagingdb="PGPASSWORD='<classnav-dev pass' psql -U classnav -W -h <rds endpoint> -p 45734 classnavdev"`

#### Prod
`alias proddb="PGPASSWORD='<classnav-prod pass>' psql -U classnav -W -h <rds endpoint -p 45734 classnav"`

and then run psql (eesh)

Or create an SSH tunnel using your db visualizer with your RSA key and the above information

Alternatively
`ssh -i <ssh rsa key> <ec2 user>@<ec2 instance> -L <local port to use>:<rds endpoint:<rds port>`
Then connect with localhost on `<local port to use>`

#### Loading local with staging data (with devcontainer)
- Get copy of staging db dump
- Open terminal
- `docker ps -a` and get container id for `skoller_api_devcontainer_postgres_1`
- Copy the dump file to the postgres container instance: `docker cp <src-path> <container>:<dest-path>`
- Connect to the container: `docker exec -it <container id> bash`
- Run psql: `psql -U postgres`
- Drop the skoller_dev db (fresh start): `DROP DATABASE skoller_dev;`
- Recreate it: `CREATE DATABASE skoller_dev;`
- Exit psql: `\q`
- Load the dump file: `psql -U postgres -d skoller_dev -f <source file>`

## NOTES
- `Skoller.Periods.generate_periods_for_all_schools_for_year()` must be run from the iex console (see IEx console on server) once a year to generate periods for all school for the current year.
- Subscription plans: month, year, premium-vip.
- Customers can be in trial, expired trial, or premium. Premium status can be gleaned by getting the users customer_id from the customers_info table and getting the info from the Strip API. (status active)



