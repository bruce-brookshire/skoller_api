defmodule Skoller.Repo.Migrations.AddFourDoorSettings do
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.Admin.Setting

  def up do
    Repo.insert!(%Setting{name: "is_diy_enabled", value: "true", topic: "FourDoor"})
    Repo.insert!(%Setting{name: "is_diy_preferred", value: "false", topic: "FourDoor"})
    Repo.insert!(%Setting{name: "is_auto_syllabus", value: "true", topic: "FourDoor"})
  end

  def down do
    Repo.delete!(%Setting{name: "is_diy_enabled", value: "true", topic: "FourDoor"})
    Repo.delete!(%Setting{name: "is_diy_preferred", value: "false", topic: "FourDoor"})
    Repo.delete!(%Setting{name: "is_auto_syllabus", value: "true", topic: "FourDoor"})
  end
end
