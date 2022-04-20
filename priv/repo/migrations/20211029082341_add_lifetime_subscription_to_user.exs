defmodule Skoller.Repo.Migrations.AddLifetimeSubscriptionToUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :lifetime_subscription, :boolean, default: false
    end
  end

  def down do
    alter table(:users) do
      remove :lifetime_subscription
    end
  end
end
