defmodule Skoller.Repo.Migrations.AddFourDoorSettings do
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.Admin.Setting

  def up do
    Repo.insert!(%Setting{name: "is_diy_enabled", value: "true", topic: "FourDoor"})
    Repo.insert!(%Setting{name: "is_diy_preferred", value: "false", topic: "FourDoor"})
    Repo.insert!(%Setting{name: "is_auto_syllabus", value: "true", topic: "FourDoor"})

    alter table(:schools) do
      remove :is_diy_enabled
      remove :is_diy_preferred
      remove :is_auto_syllabus
    end
  end
end
