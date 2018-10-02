defmodule Skoller.Repo.Migrations.AddPointEmailsToTypes do
  use Ecto.Migration

  def change do
    Skoller.Repo.insert!(%Skoller.EmailTypes.EmailType{
      id: 300,
      name: "Point Threshold Emails"
      is_active_notification: false
    })
  end
end
