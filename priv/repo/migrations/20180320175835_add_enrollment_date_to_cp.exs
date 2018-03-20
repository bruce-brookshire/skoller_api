defmodule Classnavapi.Repo.Migrations.AddEnrollmentDateToCp do
  use Ecto.Migration

  alias Classnavapi.Repo

  def up do
    alter table(:class_periods) do
      add :enroll_date, :utc_datetime
    end
    flush()
    Classnavapi.ClassPeriod
    |> Repo.all()
    |> Enum.map(&Ecto.Changeset.change(&1, %{enroll_date: &1.start_date}))
    |> Enum.each(&Repo.update!(&1))
  end

  def down do
    alter table(:class_periods) do
      remove :enroll_date
    end
  end
end
