defmodule Skoller.Repo.Migrations.AddGradYearToStudent do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :grad_year, :string
    end
  end
end
