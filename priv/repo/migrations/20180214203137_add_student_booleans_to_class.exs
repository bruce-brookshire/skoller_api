defmodule Skoller.Repo.Migrations.AddStudentBooleansToClass do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:classes) do
      add :is_student_created, :boolean, default: false, null: false
      add :is_new_class, :boolean, default: false, null: false
    end
  end
end
