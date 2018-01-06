defmodule Classnavapi.Repo.Migrations.AddUserProfilePic do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :pic_path, :string
    end
  end
end
