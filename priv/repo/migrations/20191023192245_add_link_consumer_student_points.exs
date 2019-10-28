defmodule Skoller.Repo.Migrations.AddLinkConsumerStudentPoints do
  use Ecto.Migration

  def up do
    alter table(:student_points) do
      add :link_consumer_student_id, references(:students, on_delete: :nilify_all)
    end
  end
  
  def down do
    alter table(:student_points) do
      remove :link_consumer_student_id
    end
  end
end
