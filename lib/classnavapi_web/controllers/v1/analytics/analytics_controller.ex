defmodule ClassnavapiWeb.Api.V1.Analytics.AnalyticsController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Class
  alias Classnavapi.ClassPeriod
  alias Classnavapi.Class.StudentClass

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, params) do
    syllabi = Map.new()
    |> Map.put(:class_count, class_count(params))
    |> Map.put(:enrollment, enrollment_count(params))
  end

  defp enrollment_count(%{"school_id" => school_id}) do
    from(sc in StudentClass)
    |> join(:inner, [sc], c in Class, c.id == sc.class_id)
    |> join(:inner, [sc, c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([sc, c, p], p.school_id == ^school_id)
    |> select([sc, c, p], count(sc.class_id, :distinct))
    |> Repo.one
  end
  defp enrollment_count(_params) do
    from(sc in StudentClass)
    |> select([sc], count(sc.class_id, :distinct))
    |> Repo.one
  end

  defp class_count(%{"school_id" => school_id}) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([c, p], p.school_id == ^school_id)
    |> Repo.aggregate(:count, :id)
  end
  defp class_count(_params) do
    Repo.aggregate(Class, :count, :id)
  end
end