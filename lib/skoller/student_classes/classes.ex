defmodule Skoller.StudentClasses.Classes do
  @moduledoc """
  A context module for enrolled classes.
  """

  alias Skoller.Classes.Class
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Professors.Professor
  alias Skoller.Schools.School
  alias Skoller.ClassStatuses.Status
  alias Skoller.Repo
  alias Skoller.EnrolledStudents

  import Ecto.Query

  @doc """
   Shows all `Skoller.Classes.Class` with enrollment. Can be used as a search with multiple filters.

  ## Filters:
  * school
    * `Skoller.Schools.School` :id
  * professor_name
    * `Skoller.Professors.Professor` :name
  * class_status
    * `Skoller.ClassStatuses.Status` :id
    * For ghost classes, use 0.
  * class_name
    * `Skoller.Classes.Class` :name
  * class_meet_days
    * `Skoller.Classes.Class` :meet_days

  """

  def classes_count do
    from(class in Class)
    |> join(:inner, [class], status in Status, on: status.id == class.class_status_id)
    |> select([class, status], %{
      in_reviews: fragment("sum(case when ? = '1100' OR ? = '1200' then 1 else 0 end)", status.id, status.id),
      class_changes: fragment("sum(case when ? = '1500' then 1 else 0 end)", status.id)
    })
    |> Repo.all()
  end

  def get_classes_with_enrollment(params) do
    #TODO: Filter ClassPeriod
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, on: class.class_period_id == period.id)
    |> join(:left, [class], prof in Professor, on: class.professor_id == prof.id)
    |> join(:inner, [class, period, prof], school in School, on: school.id == period.school_id)
    |> join(:inner, [class, period, prof, school], status in Status, on: status.id == class.class_status_id)
    |> join(:left, [class, period, prof, school, status], enroll in subquery(EnrolledStudents.count_subquery()), on: enroll.class_id == class.id)
    |> where([class, period, prof, school, status], ^filter(params))
    |> select([class, period, prof, school, status, enroll], %{class: class, class_period: period, professor: prof, school: school, class_status: status, enroll: enroll})
    |> sort(params)
    |> limit(500)
    |> Repo.all()
  end

  defp filter(%{} = params) do
    dynamic = params["or"] != "true"

    dynamic
    |> for_dashboard(params)
    |> search_txt_filter(params)
    |> school_filter(params)
    |> prof_filter(params)
    |> prof_id_filter(params)
    |> status_filter(params)
    |> ghost_filter(params)
    |> maint_filter(params)
    |> name_filter(params)
    |> day_filter(params)
    |> premium_filter(params)
    |> trial_filter(params)
    |> expired_filter(params)
    |> received_filter(params)
    |> days_left_filter(params)
  end

  defp for_dashboard(_dynamic, %{"dashboard" => "in_reviews"}) do
    dynamic([class, period, prof, school, status], (status.id in [1200]) and period.class_period_status_id == 200 and period.end_date > ^DateTime.utc_now())
  end
  defp for_dashboard(_dynamic, %{"dashboard" => "class_changes"}) do
    dynamic([class, period, prof, school, status], (status.id in [1500]) and period.class_period_status_id == 200)
  end
  defp for_dashboard(dynamic, _), do: dynamic

  defp search_txt_filter(dynamic, %{"search_txt" => filter, "or" => "true"}) do
    name_filter = "%" <> filter <> "%"
    id_filter = String.match?(filter, ~r/^[0-9]*$/) && filter || "-1"
    dynamic([class, period, prof, school], ((period.school_id == ^id_filter or class.id == ^id_filter) or ilike(class.name, ^name_filter) or ilike(school.name, ^name_filter)) or ^dynamic)
  end
  defp search_txt_filter(dynamic, %{"search_txt" => filter}) do
    name_filter = "%" <> filter <> "%"
    id_filter = String.match?(filter, ~r/^[0-9]*$/) && filter || "-1"
    dynamic([class, period, prof, school], ((period.school_id == ^id_filter or class.id == ^id_filter) or ilike(class.name, ^name_filter) or ilike(school.name, ^name_filter)) and ^dynamic)
  end
  defp search_txt_filter(dynamic, _), do: dynamic

  defp school_filter(dynamic, %{"school" => filter, "or" => "true"}) do
    dynamic([class, period, prof, school], period.school_id == ^filter or ^dynamic)
  end
  defp school_filter(dynamic, %{"school" => filter}) do
    dynamic([class, period, prof, school], period.school_id == ^filter and ^dynamic)
  end
  defp school_filter(dynamic, _), do: dynamic

  defp prof_filter(dynamic, %{"professor_name" => filter, "or" => "true"}) do
    prof_filter = filter <> "%"
    dynamic([class, period, prof, school], ilike(prof.name_last, ^prof_filter) or ilike(prof.name_first, ^prof_filter) or ^dynamic)
  end
  defp prof_filter(dynamic, %{"professor_name" => filter}) do
    prof_filter = filter <> "%"
    dynamic([class, period, prof, school], (ilike(prof.name_last, ^prof_filter) or ilike(prof.name_first, ^prof_filter)) and ^dynamic)
  end
  defp prof_filter(dynamic, _), do: dynamic

  defp prof_id_filter(dynamic, %{"professor_id" => filter, "or" => "true"}) do
    dynamic([class, period, prof, school], prof.id == ^filter or ^dynamic)
  end
  defp prof_id_filter(dynamic, %{"professor_id" => filter}) do
    dynamic([class, period, prof, school], prof.id == ^filter and ^dynamic)
  end
  defp prof_id_filter(dynamic, _), do: dynamic

  defp status_filter(dynamic, %{"class_status" => "0", "or" => "true"}) do
    dynamic([class, period, prof, school], class.is_ghost == true or ^dynamic)
  end
  defp status_filter(dynamic, %{"class_status" => filter, "or" => "true"}) do
    dynamic([class, period, prof, school], class.class_status_id == ^filter or ^dynamic)
  end
  defp status_filter(dynamic, %{"class_status" => "0"}) do
    dynamic([class, period, prof, school], class.is_ghost == true and ^dynamic)
  end
  defp status_filter(dynamic, %{"class_status" => filter}) do
    dynamic([class, period, prof, school], class.class_status_id == ^filter and ^dynamic)
  end
  defp status_filter(dynamic, _), do: dynamic

  defp ghost_filter(dynamic, %{"class_status" => "0"}), do: dynamic
  defp ghost_filter(dynamic, %{"ghost" => "true"}) do
    dynamic([class, period, prof, school], class.is_ghost == true and ^dynamic)
  end
  defp ghost_filter(dynamic, %{"ghost" => "false"}) do
    dynamic([class, period, prof, school], class.is_ghost == false and ^dynamic)
  end
  defp ghost_filter(dynamic, _), do: dynamic

  defp maint_filter(dynamic, %{"class_maint" => "true"}) do
    dynamic([class, period, prof, school], class.is_editable == false and ^dynamic)
  end
  defp maint_filter(dynamic, %{"class_maint" => "false"}) do
    dynamic([class, period, prof, school], class.is_editable == true and ^dynamic)
  end
  defp maint_filter(dynamic, _), do: dynamic

  defp name_filter(dynamic, %{"class_name" => filter, "or" => "true"}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof, school], ilike(class.name, ^name_filter) or ^dynamic)
  end
  defp name_filter(dynamic, %{"class_name" => filter}) do
    name_filter = "%" <> filter <> "%"
    dynamic([class, period, prof, school], ilike(class.name, ^name_filter) and ^dynamic)
  end
  defp name_filter(dynamic, _), do: dynamic

  defp day_filter(dynamic, %{"class_meet_days" => filter, "or" => "true"}) do
    dynamic([class, period, prof, school], class.meet_days == ^filter or ^dynamic)
  end

  defp day_filter(dynamic, %{"class_meet_days" => filter}) do
    dynamic([class, period, prof, school], class.meet_days == ^filter and ^dynamic)
  end

  defp day_filter(dynamic, _), do: dynamic

  defp premium_filter(dynamic, %{"premium" => filter, "or" => "true"}) do
    premium_filter = filter |> string_to_integer()
    dynamic([class, period, prof, school], class.premium == ^premium_filter or ^dynamic)
  end

  defp premium_filter(dynamic, %{"premium" => filter}) do
    premium_filter = filter |> string_to_integer()
    dynamic([class, period, prof, school], class.premium == ^premium_filter and ^dynamic)
  end
  defp premium_filter(dynamic, _), do: dynamic

  defp trial_filter(dynamic, %{"trial" => filter, "or" => "true"}) do
    trial_filter =  filter |> string_to_integer()
    dynamic([class, period, prof, school], class.trial == ^trial_filter or ^dynamic)
  end
  defp trial_filter(dynamic, %{"trial" => filter}) do
    trial_filter =  filter |> string_to_integer()
    dynamic([class, period, prof, school], class.trial == ^trial_filter and ^dynamic)
  end
  defp trial_filter(dynamic, _), do: dynamic

  defp expired_filter(dynamic, %{"expired" => filter, "or" => "true"}) do
    expired_filter = filter |> string_to_integer()
    dynamic([class, period, prof, school], class.expired == ^expired_filter or ^dynamic)
  end
  defp expired_filter(dynamic, %{"expired" => filter}) do
    expired_filter = filter |> string_to_integer()
    dynamic([class, period, prof, school], class.expired == ^expired_filter and ^dynamic)
  end
  defp expired_filter(dynamic, _), do: dynamic

  defp received_filter(dynamic, %{"received" => filter, "or" => "true"}) do
    received_filter = "%" <> filter <> "%"
    dynamic([class, period, prof, school], ilike(class.received, ^received_filter) or ^dynamic)
  end
  defp received_filter(dynamic, %{"received" => filter}) do
    received_filter = "%" <> filter <> "%"
    dynamic([class, period, prof, school], ilike(class.received, ^received_filter) and ^dynamic)
  end
  defp received_filter(dynamic, _), do: dynamic

  defp days_left_filter(dynamic, %{"days_left" => filter, "or" => "true"}) do
    days_left_filter = filter |> string_to_integer()
    dynamic([class, period, prof, school], class.days_left == ^days_left_filter or ^dynamic)
  end
  defp days_left_filter(dynamic, %{"days_left" => filter}) do
    days_left_filter = filter |> string_to_integer()
    dynamic([class, period, prof, school], class.days_left == ^days_left_filter and ^dynamic)
  end
  defp days_left_filter(dynamic, _), do: dynamic

  defp string_to_integer(string)do
    {val, ""} = Integer.parse(string)
    val
  end

  defp sort(query, %{"sort_by" => sort_by, "sort_order" => sort_order}) do
    cond do
      sort_order == "asc" || sort_order == "desc" ->
        order = String.to_atom(sort_order)
        case sort_by do
          "classname" -> order_by(query, [class, school], [{^order, class.name}])
          "school" -> order_by(query, [class, school], [{^order, school.name}])
          "premium" -> order_by(query, [class, school], [{^order, class.premium}])
          "trial" -> order_by(query, [class, school], [{^order, class.trial}])
          "expired" -> order_by(query, [class, school], [{^order, class.expired}])
          "received" -> order_by(query, [class, school], [{^order, class.received}])
          "days_left" -> order_by(query, [class, school], [{^order, class.days_left}])
          _ -> query
        end
      true -> query
    end
  end
  defp sort(query, _), do: query
end
