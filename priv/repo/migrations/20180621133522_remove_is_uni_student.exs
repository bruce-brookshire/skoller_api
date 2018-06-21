defmodule Skoller.Repo.Migrations.RemoveIsUniStudent do
  use Ecto.Migration

  def change do
    alter table(:students) do
      remove :is_university
    end
  end
end
