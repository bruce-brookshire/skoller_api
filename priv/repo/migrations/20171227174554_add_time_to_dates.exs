defmodule Classnavapi.Repo.Migrations.AddTimeToDates do
  use Ecto.Migration

  def up do

    alter table(:classes) do
      modify :class_start, :utc_datetime
      modify :class_end, :utc_datetime
    end

    alter table(:assignments) do
      modify :due, :utc_datetime
    end

  end

  def down do
    alter table(:classes) do
      modify :class_start, :date
      modify :class_end, :date
    end

    alter table(:assignments) do
      modify :due, :utc_datetime
    end
  end
end
