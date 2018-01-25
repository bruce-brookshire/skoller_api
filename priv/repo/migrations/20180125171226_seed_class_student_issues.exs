defmodule Classnavapi.Repo.Migrations.SeedClassStudentIssues do
  use Ecto.Migration

  def up do
    Classnavapi.Repo.insert!(%Classnavapi.Class.StudentRequest.Type{id: 100, name: "The wrong syllabus has been uploaded for this class"})
    Classnavapi.Repo.insert!(%Classnavapi.Class.StudentRequest.Type{id: 200, name: "Need to submit an additional/revised assignment schedule"})
    Classnavapi.Repo.insert!(%Classnavapi.Class.StudentRequest.Type{id: 300, name: "Other"})
  end

  def down do
    Classnavapi.Repo.delete!(%Classnavapi.Class.StudentRequest.Type{id: 100, name: "The wrong syllabus has been uploaded for this class"})
    Classnavapi.Repo.delete!(%Classnavapi.Class.StudentRequest.Type{id: 200, name: "Need to submit an additional/revised assignment schedule"})
    Classnavapi.Repo.delete!(%Classnavapi.Class.StudentRequest.Type{id: 300, name: "Other"})
  end
end
