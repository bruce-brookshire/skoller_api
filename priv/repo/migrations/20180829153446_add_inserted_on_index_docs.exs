defmodule Skoller.Repo.Migrations.AddInsertedOnIndexDocs do
  use Ecto.Migration

  def change do
    create index("docs", [:inserted_at])
  end
end
