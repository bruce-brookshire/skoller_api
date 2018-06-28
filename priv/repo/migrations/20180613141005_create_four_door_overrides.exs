defmodule Skoller.Repo.Migrations.CreateFourDoorOverrides do
  use Ecto.Migration

  def change do
    create table(:four_door_overrides) do
      add :is_diy_preferred, :boolean, default: false, null: false
      add :is_diy_enabled, :boolean, default: false, null: false
      add :is_auto_syllabus, :boolean, default: false, null: false
      add :school_id, references(:schools, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:four_door_overrides, [:school_id])
  end
end
