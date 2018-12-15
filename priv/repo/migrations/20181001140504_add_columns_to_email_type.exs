defmodule Skoller.Repo.Migrations.AddColumnsToEmailType do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:email_types) do
      add :category, :string
      add :is_active_email, :boolean, default: true
      add :is_active_notification, :boolean, default: true
      add :send_time, :string
    end
  end
end
