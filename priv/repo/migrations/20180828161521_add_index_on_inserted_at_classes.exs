defmodule Skoller.Repo.Migrations.AddIndexOnInsertedAtClasses do
  @moduledoc false
  use Ecto.Migration

  def change do
    create index("classes", [:inserted_at])
  end
end
