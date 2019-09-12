defmodule Skoller.Repo.Migrations.AddEmailJobsOptions do
  use Ecto.Migration

  def up do
    alter table(:email_jobs) do
      add(:options, {:map, :string})
    end
  end

  def down do
    alter table(:email_jobs) do
      remove(:options)
    end
  end
end
