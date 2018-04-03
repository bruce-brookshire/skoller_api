defmodule Classnavapi.Classes do

  alias Classnavapi.Repo
  alias Classnavapi.Class

  import Ecto.Query

  def get_class_count_by_period(period_id) do
    from(c in Class)
    |> where([c], c.class_period_id == ^period_id)
    |> Repo.aggregate(:count, :id)
  end
end