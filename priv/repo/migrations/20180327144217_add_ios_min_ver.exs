defmodule Classnavapi.Repo.Migrations.AddIosMinVer do
  use Ecto.Migration

  alias Classnavapi.Repo
  alias Classnavapi.Admin.Setting

  def up do
    Repo.insert!(%Setting{name: "min_ios_version", value: "999.999.999", topic: "MinVersions"})
  end

  def down do
    Repo.delete!(%Setting{name: "min_ios_version", value: "999.999.999", topic: "MinVersions"})
  end
end
