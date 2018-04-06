defmodule Classnavapi.Repo.Migrations.AddStudentBooleansToClass do
  use Ecto.Migration

  import Ecto.Query

  alias Classnavapi.Repo
  alias Classnavapi.Universities.Class
  alias Classnavapi.Class.Status

  def change do
    alter table(:classes) do
      add :is_student_created, :boolean, default: false, null: false
      add :is_new_class, :boolean, default: false, null: false
    end
    flush()
    from(c in Class)
    |> update([c], set: [class_status_id: 200, is_new_class: true, is_student_created: true])
    |> where([c], c.class_status_id == 100)
    |> Repo.update_all([])
  
    case Repo.get(Status, 100) do
      nil -> nil
      item -> Repo.delete!(item)
    end
  end
end
