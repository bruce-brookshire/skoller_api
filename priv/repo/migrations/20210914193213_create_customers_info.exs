defmodule Skoller.Repo.Migrations.CreateCustomersInfo do
  use Ecto.Migration

  def change do
    create table(:customers_info) do
      add :customer_id, :string
      add :payment_method, :string
      add :billing_details, :map
      add :card_info, :map
      add :user_id, references(:users, on_delete: :nothing)
      timestamps()
    end
    create index(:customers_info, [:user_id])
  end
end
