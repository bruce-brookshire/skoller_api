defmodule Skoller.Repo.Migrations.AddPointEmailsToTypes do
  use Ecto.Migration

  def change do
    Skoller.Repo.insert!(%Skoller.EmailTypes.EmailType{
      id: 300,
      name: "1000 Points Email",
      is_active_notification: false
    })
  end

  def down do
    Skoller.Repo.delete!(%Skoller.EmailTypes.EmailType{
      id: 300
    })
  end
end
