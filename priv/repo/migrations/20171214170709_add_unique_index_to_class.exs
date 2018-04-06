defmodule Skoller.Repo.Migrations.AddUniqueIndexToClass do
  use Ecto.Migration

  def change do
    create unique_index(:classes, [:class_period_id, 
                                    :professor_id,
                                    :campus,
                                    :name,
                                    :number,
                                    :meet_days,
                                    :meet_end_time,
                                    :meet_start_time], name: :unique_class_index)
  end
end