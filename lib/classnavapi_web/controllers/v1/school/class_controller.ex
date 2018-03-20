defmodule ClassnavapiWeb.Api.V1.School.ClassController do
  use ClassnavapiWeb, :controller

  @moduledoc """
  
  Handles functionality relating to classes.

  """
  
  alias Classnavapi.Class
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView
  alias ClassnavapiWeb.MinClassView

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :school

  def index(conn, %{"school_id" => school_id} = params) do
    date = DateTime.utc_now()
    query = from(class in Class)
    classes = query
    |> join(:inner, [class], period in Classnavapi.ClassPeriod, class.class_period_id == period.id)
    |> join(:left, [class], prof in Classnavapi.Professor, class.professor_id == prof.id)
    |> date_filter(params, date)
    |> where([class, period], period.school_id == ^school_id)
    |> where([class], class.is_new_class == false)
    |> where([class, period, prof], ^filter(params))
    |> select([class, period, prof], %{class: class, professor: prof, class_period: period})
    |> Repo.all()

    render(conn, ClassView, "index.json", classes: classes)
  end

  def index_min(conn, %{"school_id" => school_id} = params) do
    date = DateTime.utc_now()
    query = from(class in Class)
    classes = query
    |> join(:inner, [class], period in Classnavapi.ClassPeriod, class.class_period_id == period.id)
    |> join(:left, [class], prof in Classnavapi.Professor, class.professor_id == prof.id)
    |> date_filter(params, date)
    |> where([class, period], period.school_id == ^school_id)
    |> where([class], class.is_new_class == false)
    |> select([class, period, prof], %{class: class, professor: prof})
    |> Repo.all()

    render(conn, MinClassView, "index.json", classes: classes)
  end

  defp date_filter(query, %{"enrollable_period" => "true"}, date) do
    query
    |> where([class, period], period.enroll_date <= ^date and period.end_date >= ^date)
  end
  defp date_filter(query, _, date) do
    query
    |> where([class, period], period.start_date <= ^date and period.end_date >= ^date)
  end

  defp filter(%{} = params) do
    dynamic = params["or"] != "true"

    dynamic
    |> prof_filter(params)
    |> prof_id_filter(params)
    |> name_filter(params)
    |> number_filter(params)
  end

  defp prof_filter(dynamic, %{"professor_name" => filter, "or" => "true"}) do
    prof_filter = filter <> "%"
    dynamic([class, period, prof], ilike(prof.name_last, ^prof_filter) or ilike(prof.name_first, ^prof_filter) or ^dynamic)
  end
  defp prof_filter(dynamic, %{"professor_name" => filter}) do
    prof_filter = filter <> "%"
    dynamic([class, period, prof], (ilike(prof.name_last, ^prof_filter) or ilike(prof.name_first, ^prof_filter)) and ^dynamic)
  end
  defp prof_filter(dynamic, _), do: dynamic

  defp prof_id_filter(dynamic, %{"professor_id" => filter, "or" => "true"}) do
    dynamic([class, period, prof], prof.id == ^filter or ^dynamic)
  end
  defp prof_id_filter(dynamic, %{"professor_id" => filter}) do
    dynamic([class, period, prof], prof.id == ^filter and ^dynamic)
  end
  defp prof_id_filter(dynamic, _), do: dynamic

  defp name_filter(dynamic, %{"class_name" => filter, "or" => "true"}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_filter) or ^dynamic)
  end
  defp name_filter(dynamic, %{"class_name" => filter}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.name, ^name_filter) and ^dynamic)
  end
  defp name_filter(dynamic, _), do: dynamic

  defp number_filter(dynamic, %{"class_number" => filter, "or" => "true"}) do
    number_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.number, ^number_filter) or ^dynamic)
  end
  defp number_filter(dynamic, %{"class_number" => filter}) do
    number_filter = "%" <> filter <> "%"
    dynamic([class, period, prof], ilike(class.number, ^number_filter) and ^dynamic)
  end
  defp number_filter(dynamic, _), do: dynamic
end