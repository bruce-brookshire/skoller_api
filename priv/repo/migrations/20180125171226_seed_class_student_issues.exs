defmodule Skoller.Repo.Migrations.SeedClassStudentIssues do
  use Ecto.Migration

  def up do
    Skoller.Repo.insert!(%Skoller.Class.StudentRequest.Type{id: 100, name: "The wrong syllabus has been uploaded for this class"})
    Skoller.Repo.insert!(%Skoller.Class.StudentRequest.Type{id: 200, name: "Need to submit an additional/revised assignment schedule"})
    Skoller.Repo.insert!(%Skoller.Class.StudentRequest.Type{id: 300, name: "Other"})
  end

  def down do
    Skoller.Repo.delete!(%Skoller.Class.StudentRequest.Type{id: 100, name: "The wrong syllabus has been uploaded for this class"})
    Skoller.Repo.delete!(%Skoller.Class.StudentRequest.Type{id: 200, name: "Need to submit an additional/revised assignment schedule"})
    Skoller.Repo.delete!(%Skoller.Class.StudentRequest.Type{id: 300, name: "Other"})
  end
end
