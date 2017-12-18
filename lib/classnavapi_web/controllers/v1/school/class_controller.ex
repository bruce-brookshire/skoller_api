defmodule ClassnavapiWeb.Api.V1.School.ClassController do
  use ClassnavapiWeb, :controller

  @moduledoc """
  
  Handles functionality relating to classes.

  """
  
  alias Classnavapi.Class
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100

  @new_class_status 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :school

  def index(conn, %{"school_id" => school_id} = params) do
    date = Date.utc_today()
    query = from(class in Class)
    classes = query
    |> join(:inner, [class], period in Classnavapi.ClassPeriod, class.class_period_id == period.id)
    |> join(:left, [class], prof in Classnavapi.Professor, class.professor_id == prof.id)
    |> where([class, period], period.start_date <= ^date and period.end_date >= ^date)
    |> where([class, period], period.school_id == ^school_id)
    |> where([class], class.class_status_id != @new_class_status)
    |> where([class, period, prof], ^filter(params))
    |> Repo.all()

    render(conn, ClassView, "index.json", classes: classes)
  end

  defp filter(%{} = params) do
    dynamic = params["or"] != "true"

    dynamic
    |> prof_filter(params)
    |> prof_id_filter(params)
    |> name_filter(params)
    |> number_filter(params)
  end

  defp prof_filter(dynamic, %{"professor.name" => filter, "or" => "true"}) do
    prof_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(prof.name_last, ^prof_filter) or ^dynamic)
  end
  defp prof_filter(dynamic, %{"professor.name" => filter}) do
    prof_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(prof.name_last, ^prof_filter) and ^dynamic)
  end
  defp prof_filter(dynamic, _), do: dynamic

  defp prof_id_filter(dynamic, %{"professor.id" => filter, "or" => "true"}) do
    dynamic([class, period, prof], prof.id == ^filter or ^dynamic)
  end
  defp prof_id_filter(dynamic, %{"professor.id" => filter}) do
    dynamic([class, period, prof], prof.id == ^filter and ^dynamic)
  end
  defp prof_id_filter(dynamic, _), do: dynamic

  defp name_filter(dynamic, %{"class.name" => filter, "or" => "true"}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_filter) or ^dynamic)
  end
  defp name_filter(dynamic, %{"class.name" => filter}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_filter) and ^dynamic)
  end
  defp name_filter(dynamic, _), do: dynamic

  defp number_filter(dynamic, %{"class.number" => filter, "or" => "true"}) do
    number_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.number, ^number_filter) or ^dynamic)
  end
  defp number_filter(dynamic, %{"class.number" => filter}) do
    number_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.number, ^number_filter) and ^dynamic)
  end
  defp number_filter(dynamic, _), do: dynamic
end