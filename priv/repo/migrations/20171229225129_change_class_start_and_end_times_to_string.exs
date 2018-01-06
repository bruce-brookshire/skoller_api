defmodule Classnavapi.Repo.Migrations.ChangeClassStartAndEndTimesToString do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      modify :meet_end_time, :string
      modify :meet_start_time, :string
    end
  end
end
