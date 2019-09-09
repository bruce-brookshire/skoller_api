defmodule Skoller.Repo.Migrations.AddEmailJobsOptions do
  use Ecto.Migration

  def up do
    alter table(:email_jobs) do
      add(:options, {:map, :string})
    end
  end

  # Repo.insert!(%EmailType{
  #         id: 500,
  #         name: "Grow Community Email",
  #         category: "Class.Community",
  #         is_active_email: false,
  #         is_active_notification: false
  #       })

  #       Repo.insert!(%EmailType{
  #         id: 600,
  #         name: "Join Second Class",
  #         category: "Class.JoinSecond",
  #         is_active_email: false,
  #         is_active_notification: false
  #       })

  def down do
    alter table(:email_jobs) do
      remove(:options)
    end
  end
end
