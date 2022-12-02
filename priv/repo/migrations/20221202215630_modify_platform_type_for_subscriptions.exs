defmodule Skoller.Repo.Migrations.ModifyPlatformTypeForSubscriptions do
  use Ecto.Migration
  use Skoller.Schema.Enum.Subscriptions.SubscriptionPlatformType

  def up do
    alter table(:subscriptions) do
      remove(:platform)
    end

    execute("DROP TYPE IF EXISTS platform")

    execute(
      "CREATE TYPE platform AS ENUM (#{@platform_type_values |> Enum.map_join(",", &"'#{Atom.to_string(&1)}'")})",
      "DROP TYPE platform;"
    )

    alter table(:subscriptions) do
      add(:platform, :platform, null: true)
    end

    execute("""
      UPDATE subscriptions SET platform =
        CASE
          WHEN payment_method = 'card' THEN 'stripe'::platform
          WHEN payment_method = 'in_app' THEN 'ios'::platform
        END
    """)
  end

  def down do
    alter table(:subscriptions) do
      remove(:platform)
    end

    alter table(:subscriptions) do
      add(:platform, :platform, null: true)
    end
  end
end
