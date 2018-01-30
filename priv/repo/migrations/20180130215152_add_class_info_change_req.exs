defmodule Classnavapi.Repo.Migrations.AddClassInfoChangeReq do
  use Ecto.Migration

  def up do
    Classnavapi.Repo.insert!(%Classnavapi.Class.Change.Type{id: 400, name: "Class Info"})
  end

  def down do
    Classnavapi.Repo.delete!(%Classnavapi.Class.Change.Type{id: 400, name: "Class Info"})
  end
end
