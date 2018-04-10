defmodule Skoller.Repo.Migrations.AddTextVerification do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :verification_code, :string
      add :is_verified, :boolean, default: false, null: false
    end
  end
end
