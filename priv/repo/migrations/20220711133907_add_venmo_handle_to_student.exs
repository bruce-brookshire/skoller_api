defmodule Skoller.Repo.Migrations.AddVenmoHandleToStudent do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :venmo_handle, :string
    end
  end
end
