defmodule SkollerWeb.Api.V1.Student.Class.AssignmentController do
  use SkollerWeb, :controller

  alias Skoller.Class.StudentClass
  alias Skoller.Repo
  alias SkollerWeb.Class.StudentAssignmentView
  alias SkollerWeb.Helpers.ClassCalcs
  alias Skoller.Class.StudentAssignment
  alias Skoller.Class.Assignment
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.Helpers.ModHelper
  alias Skoller.Class.Weight
  alias SkollerWeb.Helpers.NotificationHelper
  alias Skoller.Schools.Class
  alias Skoller.Class.Status

  import Ecto.Query
  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :class
  plug :verify_member, :student
  plug :verify_member, %{of: :student_assignment, using: :id}
  plug :verify_class_is_editable, :class_id

  def create(conn, %{"class_id" => class_id, "student_id" => student_id} = params) do
    student_class = Repo.get_by!(StudentClass, class_id: class_id, student_id: student_id, is_dropped: false)

    params = params |> Map.put("student_class_id", student_class.id)

    changeset = Assignment.student_changeset(%Assignment{}, params)
    changeset = changeset
                |> Ecto.Changeset.change(%{from_mod: true})
                |> validate_class_weight()

    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:assignment, &insert_or_get_assignment(&1, changeset))
    |> Ecto.Multi.run(:student_assignment, &insert_student_assignment(&1, params))
    |> Ecto.Multi.run(:mod, &ModHelper.insert_new_mod(&1, params))

    case Repo.transaction(multi) do
      {:ok, %{student_assignment: student_assignment, mod: mod}} ->
        Task.start(ModHelper, :process_auto_update, [mod, :notification])
        Task.start(NotificationHelper, :send_mod_update_notifications, [mod])
        render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def index(conn, %{"student_id" => student_id} = params) do
    student_assignments = from(sc in StudentClass)
                          |> join(:inner, [sc], class in Class, class.id == sc.class_id)
                          |> join(:inner, [sc, class], cs in Status, cs.id == class.class_status_id)
                          |> where([sc], sc.student_id == ^student_id and sc.is_dropped == false)
                          |> where([sc, class, cs], cs.is_complete == true)
                          |> where_filters(params)
                          |> Repo.all()
                          |> Enum.flat_map(&ClassCalcs.get_assignments_with_relative_weight(&1))
                          |> Enum.map(&Map.put(&1, :is_pending_mods, is_pending_mods(&1)))
                          |> filter(params)
    render(conn, StudentAssignmentView, "index.json", student_assignments: student_assignments)
  end

  def show(conn, %{"id" => id}) do
    student_assignment = from(sc in StudentClass)
                          |> join(:inner, [sc], sa in StudentAssignment, sc.id == sa.student_class_id)
                          |> join(:inner, [sc, sa], class in Class, class.id == sc.class_id)
                          |> join(:inner, [sc, sa, class], cs in Status, cs.id == class.class_status_id)
                          |> where([sc, sa], sa.id == ^id and sc.is_dropped == false)
                          |> where([sc, sa, class, cs], cs.is_complete == true)
                          |> Repo.all()
                          |> Enum.flat_map(&ClassCalcs.get_assignments_with_relative_weight(&1))
                          |> Enum.filter(& to_string(&1.id) == id)
                          |> List.first()
    
    pending_mods = ModHelper.pending_mods_for_assignment(student_assignment)
    student_assignment = student_assignment |> Map.put(:pending_mods, pending_mods)

    render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
  end

  def update(conn, %{"id" => id} = params) do
    case get_student_assignment(id) do
      nil ->
        conn
        |> send_resp(401, "")
        |> halt()
      student_assignment -> 
        changeset = student_assignment
        |> StudentAssignment.changeset_update(params)
        |> validate_class_weight()

        multi = Ecto.Multi.new
        |> Ecto.Multi.update(:student_assignment, changeset)
        |> Ecto.Multi.run(:mod, &ModHelper.insert_update_mod(&1, changeset, params))

        case Repo.transaction(multi) do
          {:ok, %{student_assignment: student_assignment, mod: mod}} ->
            Task.start(ModHelper, :process_auto_update, [mod, :notification])
            Task.start(NotificationHelper, :send_mod_update_notifications, [mod])
            render(conn, StudentAssignmentView, "show.json", student_assignment: student_assignment)
          {:error, _, failed_value, _} ->
            conn
            |> RepoHelper.multi_error(failed_value)
        end
    end
  end

  def delete(conn, %{"id" => id} = params) do
    case get_student_assignment(id) do
      nil ->
        conn
        |> send_resp(401, "")
        |> halt()
      student_assignment -> 
        multi = Ecto.Multi.new
        |> Ecto.Multi.delete(:student_assignment, student_assignment)
        |> Ecto.Multi.run(:mod, &ModHelper.insert_delete_mod(&1, params))

        case Repo.transaction(multi) do
          {:ok, %{mod: mod}} ->
            Task.start(ModHelper, :process_auto_update, [mod, :notification])
            Task.start(NotificationHelper, :send_mod_update_notifications, [mod])
            conn
            |> send_resp(200, "")
          {:error, _, failed_value, _} ->
            conn
            |> RepoHelper.multi_error(failed_value)
        end
    end
  end

  defp order(enumerable) do
    enumerable
    |> Enum.sort(&DateTime.compare(&1.due, &2.due) in [:lt, :eq])
  end

  defp get_student_assignment(id) do
    from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, sc.id == sa.student_class_id)
    |> join(:inner, [sa, sc], class in Class, sc.class_id == class.id)
    |> where([sa], sa.id == ^id)
    |> where([sa, sc, class], class.is_editable == true)
    |> Repo.one()
  end

  defp where_filters(query, params) do
    query
    |> class_filter(params)
  end

  defp filter(enumerable, params) do
    enumerable
    |> date_filter(params)
    |> completed_filter(params)
  end

  defp class_filter(query, %{"class" => id}) do
    query
    |> where([sc], sc.class_id == ^id)
  end
  defp class_filter(query, _params), do: query

  defp date_filter(enumerable, %{"date" => date}) do
    {:ok, date, _offset} = date |> DateTime.from_iso8601()
    enumerable
    |> Enum.filter(&not(is_nil(&1.due)) and DateTime.compare(&1.due, date) in [:gt, :eq] and &1.is_completed == false)
    |> order()
  end
  defp date_filter(enumerable, _params), do: enumerable

  defp completed_filter(enumerable, %{"is_complete" => is_complete}) do
    enumerable
    |> Enum.filter(& to_string(&1.is_completed) == is_complete)
  end
  defp completed_filter(enumerable, _params), do: enumerable

  defp validate_class_weight(%Ecto.Changeset{changes: %{weight_id: nil}} = changeset), do: changeset
  defp validate_class_weight(%Ecto.Changeset{changes: %{weight_id: weight_id}, valid?: true} = changeset) do
    class_id = changeset |> get_class_id()
    case Repo.get_by(Weight, class_id: class_id, id: weight_id) do
      nil -> changeset |> Ecto.Changeset.add_error(:weight_id, "Weight class combination invalid")
      _ -> changeset
    end
  end
  defp validate_class_weight(changeset), do: changeset

  defp get_class_id(changeset) do
    case changeset |> Ecto.Changeset.get_field(:student_class_id) do
      nil -> changeset |> Ecto.Changeset.get_field(:class_id)
      val -> Repo.get!(StudentClass, val) |> Map.get(:class_id)
    end
  end

  defp is_pending_mods(assignment) do
    case ModHelper.pending_mods_for_assignment(assignment) do
      [] -> false
      _ -> true
    end
  end

  # Checks to see if an incoming changeset is identical to another student's assignment in the same class.
  defp check_student_assignment(changeset) do
    assign = from(assign in StudentAssignment)
    |> join(:inner, [assign], sc in StudentClass, sc.id == assign.student_class_id)
    |> where([assign, sc], sc.class_id == ^Ecto.Changeset.get_field(changeset, :class_id))
    |> where([assign], assign.name == ^Ecto.Changeset.get_field(changeset, :name))
    |> compare_weights(changeset)
    |> compare_dates(changeset)
    |> Repo.all()

    case assign do
      [] -> changeset |> Repo.insert()
      assign -> {:ok, assign |> List.first}
    end
  end

  # 1. Check for existing base Assignment, pass to next multi call.
  # 2. Check for existing Student Assignment, pass to next multi call. This means that a student has this assignment from a combination of mods.
  # 3. Create assignment, pass to next multi call.
  defp insert_or_get_assignment(_, %Ecto.Changeset{valid?: false} = changeset), do: {:error, changeset}
  defp insert_or_get_assignment(_, changeset) do
    assign = from(assign in Assignment)
    |> where([assign], assign.class_id == ^Ecto.Changeset.get_field(changeset, :class_id))
    |> where([assign], assign.name == ^Ecto.Changeset.get_field(changeset, :name))
    |> compare_weights(changeset)
    |> compare_dates(changeset)
    |> Repo.all()

    case assign do
      [] -> changeset |> check_student_assignment()
      assign -> {:ok, assign |> List.first}
    end
  end

  defp compare_dates(query, changeset) do
    case Ecto.Changeset.get_field(changeset, :due) do
      nil -> 
        query |> where([assign], is_nil(assign.due))
      due -> 
        query |> where([assign], ^due == assign.due)
    end
  end

  defp compare_weights(query, changeset) do
    case Ecto.Changeset.get_field(changeset, :weight_id) do
      nil ->
        query |> where([assign], is_nil(assign.weight_id))
      weight_id -> 
        query |> where([assign], ^weight_id == assign.weight_id)
    end
  end

  # 1. Check to see if assignment exists in StudentAssignment for student, if not, insert, else error.
  defp insert_student_assignment(%{assignment: %Assignment{} = assignment}, params) do
    params = params |> Map.put("assignment_id", assignment.id)
    changeset = StudentAssignment.changeset(%StudentAssignment{}, params)

    student_assign = from(assign in StudentAssignment)
    |> where([assign], assign.student_class_id == ^params["student_class_id"])
    |> where([assign], assign.assignment_id == ^assignment.id)
    |> Repo.all()

    case student_assign do
      [] -> Repo.insert(changeset)
      _ -> {:error, %{student_assignment: "Assignment is already added."}}
    end
  end
  defp insert_student_assignment(%{assignment: %StudentAssignment{} = student_assignment}, params) do
    params = params |> Map.put("assignment_id", student_assignment.assignment_id)
    changeset = StudentAssignment.changeset(%StudentAssignment{}, params)

    student_assign = from(assign in StudentAssignment)
    |> where([assign], assign.student_class_id == ^params["student_class_id"])
    |> where([assign], assign.assignment_id == ^student_assignment.assignment_id)
    |> Repo.all()

    case student_assign do
      [] -> Repo.insert(changeset)
      _ -> {:error, %{student_assignment: "Assignment is already added."}}
    end
  end
end