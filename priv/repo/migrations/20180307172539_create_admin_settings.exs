defmodule Classnavapi.Repo.Migrations.CreateAdminSettings do
  use Ecto.Migration

  alias Classnavapi.Repo

  def change do
    create table(:admin_settings, primary_key: false) do
      add :name, :string, primary_key: true
      add :topic, :string
      add :value, :string

      timestamps()
    end

    flush()
    Repo.insert!(%Classnavapi.Admin.Setting{name: "auto_upd_enroll_thresh", topic: "AutoUpdate", value: "5"})
    Repo.insert!(%Classnavapi.Admin.Setting{name: "auto_upd_response_thresh", topic: "AutoUpdate", value: "0.35"})
    Repo.insert!(%Classnavapi.Admin.Setting{name: "auto_upd_approval_thresh", topic: "AutoUpdate", value: "0.75"})
  end
end
