defmodule Classnavapi.Repo.Migrations.InsertHelpRole do
  use Ecto.Migration

  def up do
    Classnavapi.Repo.insert!(%Classnavapi.Role{id: 500, name: "Help Requests"})
  end
  def down do
    Classnavapi.Repo.delete!(%Classnavapi.Role{id: 500, name: "Help Requests"})
  end
end
