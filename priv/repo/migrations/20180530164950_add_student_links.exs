defmodule Skoller.Repo.Migrations.AddStudentLinks do
  use Ecto.Migration

  alias Skoller.Students.Student
  alias Skoller.Students
  alias Skoller.Repo

  import Ecto.Query

  def up do
    alter table(:students) do
      add :enrollment_link, :string
      add :enrolled_by, references(:students, on_delete: :nilify_all)
    end
    flush()
    from(s in Student)
    |> where([s], is_nil(s.enrollment_link))
    |> Repo.all()
    |> Enum.map(&Students.generate_student_link(&1))
  end

  def down do
    alter table(:students) do
      remove :enrollment_link
      remove :enrolled_by
    end
  end
end