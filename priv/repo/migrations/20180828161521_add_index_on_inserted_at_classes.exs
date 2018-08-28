defmodule Skoller.Repo.Migrations.AddIndexOnInsertedAtClasses do
  use Ecto.Migration

  def change do
    create index("classes", [:inserted_at])
  end
end
