defmodule Skoller.Repo.Migrations.UsersLastLogIn do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :last_login, :utc_datetime
    end
  end

  def down do
    alter table(:users) do
      remove :last_login
    end
  end
end
