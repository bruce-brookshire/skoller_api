defmodule Classnavapi.Repo.Migrations.CreateClassStatuses do
  use Ecto.Migration

  def change do
    create table(:class_statuses) do
      add :name, :string
      add :is_editable, :boolean, null: false
      add :is_complete, :boolean, null: false

      timestamps()
    end

  end
end
