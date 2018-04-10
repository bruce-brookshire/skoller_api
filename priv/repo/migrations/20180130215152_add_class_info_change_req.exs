defmodule Skoller.Repo.Migrations.AddClassInfoChangeReq do
  use Ecto.Migration

  def up do
    Skoller.Repo.insert!(%Skoller.Class.Change.Type{id: 400, name: "Class Info"})
  end

  def down do
    Skoller.Repo.delete!(%Skoller.Class.Change.Type{id: 400, name: "Class Info"})
  end
end
