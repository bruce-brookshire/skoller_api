defmodule Skoller.Repo.Migrations.AddColumnsToEmailType do
  use Ecto.Migration

  def change do
    alter table(:email_types) do
      add :category, :string
      add :is_active_email, :boolean, default: true
      add :is_active_notification, :boolean, default: true
      add :send_time, :string
    end

    flush()

    Skoller.Repo.delete_all(Skoller.EmailTypes.EmailType)
    Skoller.Repo.insert!(%Skoller.EmailTypes.EmailType{
      id: 100,
      name: "No Classes Email",
      send_time: "09:00:00",
      category: "Class.None"
    })
    Skoller.Repo.insert!(%Skoller.EmailTypes.EmailType{
      id: 200,
      name: "Class Setup Email",
      send_time: "09:00:00",
      category: "Class.Setup"
    })
  end
end
