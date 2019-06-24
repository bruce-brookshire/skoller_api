defmodule Skoller.Repo.Migrations.AddStudentLoginTimeout do
  use Ecto.Migration

  def up do
    alter table(:students) do
      add(:login_attempt, :utc_datetime)
    end
  end

  def down do
    alter table(:students) do
      remove(:login_attempt, :utc_datetime)
    end
  end
end
