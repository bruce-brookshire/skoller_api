defmodule Skoller.Repo.Migrations.AddClassUploadKey do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      add :class_upload_key, :string
    end
  end
end
