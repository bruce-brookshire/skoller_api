defmodule Classnavapi.Repo.Migrations.AddTextVerification do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :verification_code, :string
    end
  end
end
