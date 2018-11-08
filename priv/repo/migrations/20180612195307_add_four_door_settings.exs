defmodule Skoller.Repo.Migrations.AddFourDoorSettings do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:schools) do
      remove :is_diy_enabled
      remove :is_diy_preferred
      remove :is_auto_syllabus
    end
  end
end
