defmodule Skoller.Repo.Migrations.AddStudentBooleansToClass do
  use Ecto.Migration

  import Ecto.Query

  alias Skoller.Repo
  alias Skoller.Schools.Class
  alias Skoller.Classes.Status

  def change do
    alter table(:classes) do
      add :is_student_created, :boolean, default: false, null: false
      add :is_new_class, :boolean, default: false, null: false
    end
  end
end
