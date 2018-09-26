defmodule Skoller.Classes.Schools do
  @moduledoc """
  
  A context module for class schools

  """

  alias Skoller.Classes.Class
  alias Skoller.Periods.ClassPeriod

  import Ecto.Query

  @doc """
  Gets all class_id and school_id.

  ## Params
  `%{"school_id" => id}`, gets all classes in in school
  """
  def get_school_from_class_subquery(_params \\ %{})
  def get_school_from_class_subquery(%{"school_id" => school_id}) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([c, p], p.school_id == ^school_id)
    |> select([c, p], %{class_id: c.id, school_id: p.school_id})
  end
  def get_school_from_class_subquery(_params) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> select([c, p], %{class_id: c.id, school_id: p.school_id})
  end
end