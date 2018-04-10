defmodule Skoller.Repo.Migrations.AddDropClassColumn do
  use Ecto.Migration

  def change do
    alter table(:student_classes) do
      add :is_dropped, :boolean, default: false, null: false
    end
  end
end
