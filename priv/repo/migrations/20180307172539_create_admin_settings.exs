defmodule Classnavapi.Repo.Migrations.CreateAdminSettings do
  use Ecto.Migration

  alias Classnavapi.Repo

  def change do
    create table(:admin_settings, primary_key: false) do
      add :name, :string, primary_key: true
      add :value, :string

      timestamps()
    end

    flush()
    Repo.insert!(%Classnavapi.Admin.Settings{name: "auto_upd_enroll_thresh", value: "5"})
    Repo.insert!(%Classnavapi.Admin.Settings{name: "auto_upd_response_thresh", value: "0.35"})
    Repo.insert!(%Classnavapi.Admin.Settings{name: "auto_upd_approval_thresh", value: "0.75"})
  end
end
