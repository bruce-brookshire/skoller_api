defmodule Skoller.Repo.Migrations.AddUniqueIndexSemesters do
  use Ecto.Migration

  def change do
    create unique_index(:class_periods, [:name, :school_id], name: :unique_semester_index)
  end
end
