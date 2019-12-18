defmodule Skoller.Repo.Migrations.FourDoorToSyllabusOverload do
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.Settings.Setting

  import Ecto.Query

  def up do
    drop(table(:four_door_overrides))

    from("admin_settings")
    |> where([s], s.topic == "FourDoor")
    |> Repo.delete_all()

    Setting.changeset(%Setting{}, %{
      name: "syllabus_overload_override",
      topic: "SyllabusOverload",
      value: "false"
    })
    |> Repo.insert()

    alter table(:schools) do
      add(:is_syllabus_overload, :boolean, default: false)
    end
  end

  def down do
    create table(:four_door_overrides) do
      add(:is_diy_preferred, :boolean, default: false, null: false)
      add(:is_diy_enabled, :boolean, default: false, null: false)
      add(:is_auto_syllabus, :boolean, default: false, null: false)
      add(:school_id, references(:schools, on_delete: :delete_all))

      timestamps()
    end

    create(unique_index(:four_door_overrides, [:school_id]))

    alter table(:schools) do
      remove(:is_syllabus_overload)
    end

    from("admin_settings")
    |> where([s], s.topic == "SyllabusOverload")
    |> Repo.delete_all()
  end
end
