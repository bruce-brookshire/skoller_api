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
      is_active_email: true,
      is_active_notification: true
    })
  end

  def down do
    alter table(:email_jobs) do
      remove(:options)
    end

    EmailType
    |> Repo.get_by(category: "Class.Community")
    |> Repo.delete()
  end
end
