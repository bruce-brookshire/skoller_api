defmodule Classnavapi.Repo.Migrations.ConvertGradeScaleToBlob do
  use Ecto.Migration

  alias Classnavapi.Repo
  alias Classnavapi.Universities.Class

  def up do
    alter table(:classes) do
      add :grade_scale_map, :map
    end
    flush()
    Class
    |> Repo.all()
    |> Enum.map(&Ecto.Changeset.change(&1, %{grade_scale_map: convert_gs_to_map(&1.grade_scale)}))
    |> Enum.each(&Repo.update!(&1))
  end

  def down do
    alter table(:classes) do
      remove :grade_scale_map
    end
  end

  defp convert_gs_to_map(gs) do
    gs
    |> String.trim_trailing("|")
    |> String.split("|")
    |> Enum.map(&String.split(&1, ","))
    |> Enum.sort(&List.last(&1) >= List.last(&2))
    |> Enum.reduce(%{}, &Map.put(&2, List.first(&1), List.last(&1)))
  end
end

