defmodule Skoller.Repo.Migrations.SplitClassValues do
  use Ecto.Migration

  def change do
    drop index("classes", [], name: :unique_class_index)
    rename table("classes"), :number, to: :code
    alter table(:classes) do
      add :section, :string
      add :subject, :string
      remove :is_enrollable
    end
    create unique_index(:classes, [:class_period_id, 
                                    :professor_id,
                                    :campus,
                                    :name,
                                    :code,
                                    :section,
                                    :subject,
                                    :meet_days,
                                    :meet_end_time,
                                    :meet_start_time], name: :unique_class_index)
  end
end
