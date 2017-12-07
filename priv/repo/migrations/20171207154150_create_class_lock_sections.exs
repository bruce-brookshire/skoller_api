defmodule Classnavapi.Repo.Migrations.CreateClassLockSections do
  use Ecto.Migration

  def change do
    create table(:class_lock_sections) do
      add :name, :string

      timestamps()
    end

  end
end
