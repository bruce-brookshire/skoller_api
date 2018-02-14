defmodule Classnavapi.Repo.Migrations.AddStudentBooleansToClass do
  use Ecto.Migration

  import Ecto.Query

  def change do
    alter table(:classes) do
      add :is_student_created, :boolean, default: false, null: false
      add :is_new_class, :boolean, default: false, null: false
    end
    flush()
    from(c in Classnavapi.Class)
    |> update([c], set: [class_status_id: 200, is_new_class: true, is_student_created: true])
    |> where([c], c.class_status_id == 100)
    |> Classnavapi.Repo.update_all([])
  
    Classnavapi.Repo.delete!(%Classnavapi.Class.Status{id: 100, name: "New Class"})
  end
end
