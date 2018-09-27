defmodule Skoller.Repo.Migrations.CreateStudentPointTypes do
  @moduledoc false
  use Ecto.Migration

  import Ecto.Query

  alias Skoller.Repo
  alias Skoller.StudentPoints.PointType
  alias Skoller.StudentPoints.StudentPoint
  alias Skoller.Students.Student
  alias Skoller.StudentClasses.StudentClass

  def change do
    create table(:student_point_types) do
      add :name, :string
      add :value, :integer
      add :is_one_time, :boolean, default: false, null: false

      timestamps()
    end
    flush()
    Repo.insert!(%PointType{name: "Class Referral", value: 100})
    Repo.insert!(%PointType{name: "Student Referral", value: 100})

    create table(:student_points) do
      add :value, :integer
      add :student_id, references(:students, on_delete: :nothing)
      add :student_point_type_id, references(:student_point_types, on_delete: :nothing)

      timestamps()
    end

    create index(:student_points, [:student_id])
    create index(:student_points, [:student_point_type_id])
    flush()

    students = from(s in Student)
    |> where([s], not(is_nil(s.enrolled_by)))
    |> Repo.all()

    student_point_type = Repo.get_by(PointType, name: "Student Referral")

    students |> Enum.each(&Repo.insert!(%StudentPoint{student_id: &1.enrolled_by, student_point_type_id: student_point_type.id, value: student_point_type.value}))

    student_ids = from(sc in StudentClass)
    |> join(:inner, [sc], eb in StudentClass, sc.id == eb.enrolled_by)
    |> select([sc], sc.student_id)
    |> Repo.all()

    student_point_type = Repo.get_by(PointType, name: "Class Referral")

    student_ids |> Enum.each(&Repo.insert!(%StudentPoint{student_id: &1, student_point_type_id: student_point_type.id, value: student_point_type.value}))
  end
end
