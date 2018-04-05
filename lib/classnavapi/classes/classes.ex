defmodule Classnavapi.Classes do

  alias Classnavapi.Repo
  alias Classnavapi.Class
  alias Classnavapi.Schools.ClassPeriod
  alias Classnavapi.Class.Status

  import Ecto.Query

  def get_class_count_by_period(period_id) do
    from(c in Class)
    |> where([c], c.class_period_id == ^period_id)
    |> Repo.aggregate(:count, :id)
  end

  def get_status_counts(school_id) do
    from(class in Class)
    |> join(:inner, [class], prd in ClassPeriod, class.class_period_id == prd.id)
    |> join(:full, [class, prd], status in Status, class.class_status_id == status.id)
    |> where([class, prd], prd.school_id == ^school_id)
    |> group_by([class, prd, status], [status.name])
    |> select([class, prd, status], %{status: status.name, count: count(class.id)})
    |> Repo.all()
  end
end