defmodule Classnavapi.Repo.Migrations.CreateUserDevices do
  use Ecto.Migration

  def change do
    create table(:user_devices) do
      add :udid, :string
      add :type, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:user_devices, [:user_id])
    create unique_index(:user_devices, [:user_id, :udid])
  end
end
