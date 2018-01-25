defmodule Classnavapi.Repo.Migrations.CreateClassStudentRequestType do
  use Ecto.Migration

  def change do
    create table(:class_student_request_types) do
      add :name, :string

      timestamps()
    end
  end
end
