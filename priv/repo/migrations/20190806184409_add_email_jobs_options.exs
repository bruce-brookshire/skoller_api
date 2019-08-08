defmodule Skoller.Repo.Migrations.AddEmailJobsOptions do
  use Ecto.Migration

  alias Skoller.EmailTypes.EmailType
  alias Skoller.Repo

  def up do
    alter table(:email_jobs) do
      add(:options, :string)
    end

    Repo.insert!(%EmailType{
      id: 500,
      name: "Grow Community Email",
      category: "Class.Community",
      is_active_email: false,
      is_active_notification: false
    })
    
    Repo.insert!(%EmailType{
      id: 600,
      name: "Join Second Class",
      category: "Class.JoinSecond",
      is_active_email: false,
      is_active_notification: false
    })
  end

  def down do
    alter table(:email_jobs) do
      remove(:options)
    end

    EmailType
    |> Repo.get_by(id: 500)
    |> Repo.delete()

    EmailType
    |> Repo.get_by(id: 600)
    |> Repo.delete()
  end
end
