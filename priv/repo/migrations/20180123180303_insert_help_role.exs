defmodule Skoller.Repo.Migrations.InsertHelpRole do
  use Ecto.Migration

  def up do
    Skoller.Repo.insert!(%Skoller.Role{id: 500, name: "Help Requests"})
  end
  def down do
    Skoller.Repo.delete!(%Skoller.Role{id: 500, name: "Help Requests"})
  end
end
