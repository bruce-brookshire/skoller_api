defmodule Skoller.Repo.Migrations.ClassesAddNewColumns do
  use Ecto.Migration

  def change do
    alter table("classes")do
      add :premium, :integer
      add :trial, :integer
      add :expired, :integer
      add :received, :string
      add :days_left, :integer
    end
  end
end
