defmodule Classnavapi.Schools do
  @moduledoc """
  The Schools context.
  """

  alias Classnavapi.Repo
  alias Classnavapi.Schools.School
  alias Classnavapi.Schools.ClassPeriod

  import Ecto.Query

  def get_school_from_period(class_period_id) do
    from(cp in ClassPeriod)
    |> join(:inner, [cp], s in School, s.id == cp.school_id)
    |> where([cp], cp.id == ^class_period_id)
    |> select([cp, s], s)
    |> Repo.one()
  end

end