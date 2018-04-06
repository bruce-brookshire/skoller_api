defmodule Skoller.Repo.Migrations.AddIosMinVer do
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.Admin.Setting

  def up do
    Repo.insert!(%Setting{name: "min_ios_version", value: "0.0.0", topic: "MinVersions"})
    Repo.insert!(%Setting{name: "min_android_version", value: "0.0.0", topic: "MinVersions"})
  end

  def down do
    Repo.delete!(%Setting{name: "min_ios_version", value: "0.0.0", topic: "MinVersions"})
    Repo.delete!(%Setting{name: "min_android_version", value: "0.0.0", topic: "MinVersions"})
  end
end
