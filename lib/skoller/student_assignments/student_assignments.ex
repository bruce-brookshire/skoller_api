defmodule Skoller.StudentAssignments do
  @moduledoc """
  The context module for student assignments.
  """

  alias Skoller.Repo
  alias Skoller.StudentAssignments.StudentAssignment
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Assignments.Assignment
  alias Skoller.Weights.Weight
  alias Skoller.Mods
  alias Skoller.StudentClasses
  alias Skoller.Classes.Weights
  alias Skoller.Assignments.Classes
  alias Skoller.AutoUpdates
  alias Skoller.ModNotifications

  import Ecto.Query

  require Logger

  @doc """
  Gets a student assignment by assignment id and student class id.

  ## Returns
  `Skoller.StudentAssignments.StudentAssignment` or `nil`
  """
  def get_assignment_by_ids(assignment_id, student_class_id) do
    Repo.get_by(StudentAssignment, assignment_id: assignment_id, student_class_id: student_class_id)
  end

  @doc """
  Gets a student assignment by assignment id and student class id.

  ## Returns
  `Skoller.StudentAssignments.StudentAssignment` or `Ecto.NoResultsError`
  """
  def get_assignment_by_ids!(assignment_id, student_class_id) do
    Repo.get_by!(StudentAssignment, assignment_id: assignment_id, student_class_id: student_class_id)
  end

  @doc """
  Inserts assignments for all students in the class, or inserts all class assignments for a student.

  ## Behavior
   * Passing a `Skoller.StudentClasses.StudentClass` will cause the student to get all assignments for the class.
   * Passing a `Skoller.Assignments.Assignment` will cause all students to get the assignment.

  ## Returns
  `{:ok, [Skoller.StudentAssignments.StudentAssignment]}` or `{:ok, nil}` if there are no students or assignments
  or `{:error, %{student_class: "Student Assignments not inserted"}}` if something went wrong.
  """
  # TODO: I made this when I first started Elixir. This is absolutely awful.
  # It needs to be split out depending on what is calling it, and likely into different modules altogether.
  def insert_assignments(student_class_or_assignment_struct)
  def insert_assignments(%{student_class: %StudentClass{} = student_class}) do
    Logger.info("inserting assignments for student class: " <> to_string(student_class.id))
    case Classes.get_assignments_by_class(student_class.class_id) do
      [] -> {:ok, nil}
      assignments -> convert_and_insert(assignments, student_class)
    end
  end
  def insert_assignments(%{assignment: %Assignment{} = assignment}) do
    Logger.info("inserting assignment: " <> to_string(assignment.id) <> " for students")
    case StudentClasses.get_studentclasses_by_class(assignment.class_id) do
      [] -> {:ok, nil}
      students -> convert_and_insert(assignment, students)
    end
  end

  @doc """
  Updates student assignments when a class assignment is changed.

  ## Behavior
   * This will currently overwrite all mods a student has accepted and not reset the mods.

  ## Returns
  `{:ok, [Skoller.StudentAssignments.StudentAssignment]}` or `{:ok, nil}` if there are no students or assignments
  or `{:error, %{student_class: "Student Assignments not updated"}}` if something went wrong.
  """
  def update_assignments(%{assignment: %Assignment{} = assignment}) do
    case StudentClasses.get_studentclasses_by_class(assignment.class_id) do
      [] -> {:ok, nil}
      students -> convert_and_update(assignment, students)
    end
  end

  @doc """
  Converts an assignment into a student assignment.

  ## Returns
  `Skoller.StudentAssignments.StudentAssignment`
  """
  def convert_assignment(%Assignment{} = assignment, %StudentClass{id: id}) do
    %StudentAssignment{
      name: assignment.name,
      weight_id: assignment.weight_id,
      assignment_id: assignment.id,
      student_class_id: id,
      due: assignment.due
    }
  end

  @doc """
  Gets the class completion for a student.

  ## Returns
  `Decimal`
  """
  def get_class_completion(%StudentClass{id: student_class_id} = student_class) do
    relative_weights = get_relative_weight(student_class)

    student_class_id
    |> get_completed_assignments()
    |> Enum.reduce(Decimal.new(0), &Decimal.add(get_weight(&1, relative_weights), &2))
  end

  @doc """
  Gets assignments with relative weights by either StudentAssignment or Assignments based on params.

  ## Returns
  `[Skoller.StudentAssignments.StudentAssignment]`, `[Skoller.Assignments.Assignment]`, or `[]`
  If the structs are returned, they will have a `:relative_weight` key.
  """
  # TODO: This is messy too, just like the other stuff. Try to split it out a bit.
  def get_assignments_with_relative_weight(%{} = params) do #good.
    assign_weights = get_relative_weight(params)

    params
    |> get_assignments()
    |> Enum.map(&Map.put(&1, :relative_weight, get_weight(&1, assign_weights)))
  end

  @doc """
  Creates a student assignment. Also creates a mod.

  Will send notifications on success if auto update is triggered.
  Will send a notification for a mod being created as well.

  ## Returns
  `{:ok, student_assignment: Skoller.StudentAssignments.StudentAssignment}` or `{:error, changeset}`
  """
  def create_student_assignment(params) do
    #Insert into assignments as from_mod as well.
    changeset = Assignment.student_changeset(%Assignment{}, params)
    |> Ecto.Changeset.change(%{from_mod: true})
    |> validate_class_weight()

    result = Ecto.Multi.new
    |> Ecto.Multi.run(:assignment, fn (_, changes) -> insert_or_get_assignment(changes, changeset) end)
    |> Ecto.Multi.run(:student_assignment, fn (_, changes) -> insert_student_assignment(changes, params) end)
    |> Ecto.Multi.run(:mod, fn (_, changes) -> Mods.insert_new_mod(changes, params["student_id"], params["is_private"]) end)
    |> Repo.transaction()
    |> process_auto_update()
    |> mod_update_notification()

    case result do
      {:ok, %{student_assignment: student_assignment}} ->
        {:ok, student_assignment}
      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a student assignment. Also creates a mod.

  Will send notifications on success if auto update is triggered.
  Will send a notification for a mod being created as well.

  ## Returns
  `{:ok, student_assignment: Skoller.StudentAssignments.StudentAssignment}` or `{:error, changeset}`
  """
  def update_student_assignment(old, params) do
    changeset = old
    |> StudentAssignment.changeset_update(params)
    |> validate_class_weight()

    result = Ecto.Multi.new
    |> Ecto.Multi.update(:student_assignment, changeset)
    |> Ecto.Multi.run(:mod, fn (_, changes) -> Mods.insert_update_mod(changes, changeset, params["is_private"]) end)
    |> Repo.transaction()
    |> process_auto_update()
    |> mod_update_notification()

    case result do
      {:ok, %{student_assignment: student_assignment}} ->
        {:ok, student_assignment}
      {:error, _, changeset, _} ->
        {:error, changeset}
    end
    |> IO.inspect
  end

  @doc """
  Deletes a student assignment and creates a mod if a public change.

  Will send notificatons and potentially auto update.
  """
  def delete_student_assignment(student_assignment, is_private) do
    result = Ecto.Multi.new
    |> Ecto.Multi.delete(:student_assignment, student_assignment)
    |> Ecto.Multi.run(:mod, fn (_, changes) -> Mods.insert_delete_mod(changes, is_private) end)
    |> Repo.transaction()
    |> process_auto_update()
    |> mod_update_notification()

    case result do
      {:ok, %{student_assignment: student_assignment}} ->
        {:ok, student_assignment}
      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates an assignment grade.

  ## Returns
  `{:ok, student_assignment}` or `{:error, changeset}`
  """
  def update_assignment_grade(assign_old, params) do
    assign_old
    |> StudentAssignment.grade_changeset(params)
    |> Repo.update()
  end

  defp mod_update_notification({:ok, %{mod: %{actions: actions}}} = result) do
    Logger.info("Sending update notifications for mods 1")
    Logger.info("Actions: #{inspect actions}")
    Task.start(ModNotifications, :send_mod_update_notifications, [actions])
    result
  end
  # TODO: Normalize return results from insert_update_mod so this doens't need to exist.
  defp mod_update_notification({:ok, %{mod: mod}} = result) do
    mod_results = Keyword.get(mod, :ok)
    case mod_results do
      %{actions: actions} ->
        Logger.info("Sending update notifications for mods 2")
        Logger.info("Actions: #{inspect actions}")
        Task.start(ModNotifications, :send_mod_update_notifications, [actions])
      _ ->
        {:ok, nil}
    end
    result
  end
  defp mod_update_notification(result), do: result

  defp process_auto_update({:ok, %{mod: %{mod: mod}}} = result) do
    Task.start(AutoUpdates, :process_auto_update, [mod, [notification: true]])
    result
  end
  # TODO: Normalize return results from insert_update_mod so this doens't need to exist.
  defp process_auto_update({:ok, %{mod: mod}} = result) do
    mod_results = Keyword.get(mod, :ok)
    case mod_results do
      %{mod: mod} ->
        Task.start(AutoUpdates, :process_auto_update, [mod, [notification: true]])
      _ ->
        {:ok, nil}
    end
    result
  end
  defp process_auto_update(result), do: result

  # Gets a student's assignments, gets student's assignments by id, or gets class assignments

  # ## Behavior
  #  * If passed a student class, gets all student assignments for that student class.
  #  * If passed an assignment, gets all student assignments for that assignment.
  #  * If passed a map containing `%{class_id: class_id}`, gets all assignments for that class.

  # ## Returns
  # `[Skoller.StudentAssignments.StudentAssignment]`, `[Skoller.Assignments.Assignment]`, or `[]`
  
  # TODO: I made this when I first started Elixir. This is absolutely awful.
  # This is the single worst piece of code.
  # Anyways. This needs help. This should not do 3 different things.
  defp get_assignments(%StudentClass{id: id}) do
    query = (from assign in StudentAssignment)
    query
    |> where([assign], assign.student_class_id == ^id)
    |> Repo.all()
  end
  defp get_assignments(%Assignment{id: id}) do
    query = (from assign in StudentAssignment)
    query
    |> where([assign], assign.assignment_id == ^id)
    |> Repo.all()
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
    |> Repo.one()

    case assign do
      nil -> changeset |> check_student_assignment()
      assign -> {:ok, assign}
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

  # Checks to see if an incoming changeset is identical to another student's assignment in the same class.
  defp check_student_assignment(changeset) do
    assign = from(assign in StudentAssignment)
    |> join(:inner, [assign], sc in StudentClass, on: sc.id == assign.student_class_id)
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

  # Gets a class id from a student assignment.
  defp get_class_id_from_student_assignment_changeset(changeset) do
    case changeset |> Ecto.Changeset.get_field(:student_class_id) do
      nil -> changeset |> Ecto.Changeset.get_field(:class_id)
      val -> StudentClasses.get_student_class_by_id!(val) |> Map.get(:class_id)
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

  # Makes sure the weight is actually a part of the class.
  defp validate_class_weight(%Ecto.Changeset{changes: %{weight_id: nil}} = changeset), do: changeset
  defp validate_class_weight(%Ecto.Changeset{changes: %{weight_id: weight_id}, valid?: true} = changeset) do
    class_id = changeset |> get_class_id_from_student_assignment_changeset()
    case Weights.get_class_weight_by_ids(class_id, weight_id) do
      nil -> changeset |> Ecto.Changeset.add_error(:weight_id, "Weight class combination invalid")
      _ -> changeset
    end
  end
  defp validate_class_weight(changeset), do: changeset

  # Gets completed assignments for a student class.
  defp get_completed_assignments(student_class_id) do
    query = from(assign in StudentAssignment)
    query
    |> where([assign], assign.student_class_id == ^student_class_id)
    |> where([assign], not(is_nil(assign.grade)))
    |> where([assign], not(is_nil(assign.weight_id)))
    |> Repo.all()
  end

  # Attempts to find a weight in the assignment_or_student_assignment_enumerable, or returns 0.
  defp get_weight(%{weight_id: weight_id}, assignment_or_student_assignment_enumerable) do
    assignment_or_student_assignment_enumerable
    |> Enum.find(%{}, & &1.weight_id == weight_id)
    |> Map.get(:relative, Decimal.new(0))
  end

  # Returns the relative weight for each weight category.
  defp get_relative_weight(%{class_id: class_id} = params) do
    assign_count = from(w in Weight)
    |> join(:left, [w], s in subquery(relative_weight_subquery(params)), on: s.weight_id == w.id)
    |> where([w], w.class_id == ^class_id)
    |> select([w, s], %{weight: w.weight, count: s.count, weight_id: w.id})
    |> Repo.all()
    
    weight_sum = assign_count 
    |> Enum.filter(& &1.weight != nil)
    |> Enum.reduce(Decimal.new(0), &Decimal.add(&1.weight, &2))

    assign_count
    |> Enum.map(&Map.put(&1, :relative, calc_relative_weight(&1, weight_sum)))
  end

  # This gets the count of assignments and the weight id for either a student class or a class.
  # If it is for a class, it will only be for assignments that are not mods.
  # TODO: Split logic here.
  defp relative_weight_subquery(%StudentClass{id: id}) do #good
    query = (from assign in StudentAssignment)
    query
    |> join(:inner, [assign], weight in Weight, on: assign.weight_id == weight.id)
    |> where([assign], assign.student_class_id == ^id)
    |> group_by([assign, weight], [assign.weight_id, weight.weight])
    |> select([assign, weight], %{count: count(assign.id), weight_id: assign.weight_id})
  end
  defp relative_weight_subquery(%{class_id: class_id}) do
    query = (from assign in Assignment)
    query
    |> join(:inner, [assign], weight in Weight, on: assign.weight_id == weight.id)
    |> where([assign], assign.class_id == ^class_id)
    |> where([assign], assign.from_mod == false)
    |> group_by([assign, weight], [assign.weight_id, weight.weight])
    |> select([assign, weight], %{count: count(assign.id), weight_id: assign.weight_id})
  end

  defp calc_relative_weight(%{count: nil}, _weight_sum), do: Decimal.new(0)
  defp calc_relative_weight(%{weight: weight, count: count}, weight_sum) do
    weight
    |> Decimal.div(Decimal.new(weight_sum))
    |> Decimal.div(Decimal.new(count))
  end

  defp convert_and_insert(assignment, student_class) do
    assignment
    |> convert_assignments(student_class)
    |> insert()

    case get_inserted(student_class, assignment) do
      [] -> {:error, %{student_class: "Student Assignments not inserted"}}
      inserted -> {:ok, inserted}
    end
  end

  #TODO: Bug here. Mods need to be handled. See Trello
  # Likely bug: in Skoller.StudentAssignments.convert_and_update/2, mods not being considered.
  defp convert_and_update(assignment, student_class) do
    assignment
    |> convert_assignments(student_class)
    |> Enum.each(&update_assignment(&1))

    case get_inserted(student_class, assignment) do
      [] -> {:error, %{student_class: "Student Assignments not updated"}}
      updated -> {:ok, updated}
    end
  end

  defp get_inserted(%StudentClass{} = student_class, _enumerable) do
    student_class
    |> get_assignments
  end

  defp get_inserted(_enumerable, %Assignment{} = assignment) do
    assignment
    |> get_assignments
  end

  defp convert_assignments(enumerable, %StudentClass{} = student_class) do
    enumerable |> Enum.map(&convert_assignment(&1, student_class))
  end

  defp convert_assignments(%Assignment{} = assign, enumerable) do
    enumerable |> Enum.map(&convert_assignment(assign, &1))
  end

  defp insert(enumerable) do
    enumerable
    |> Enum.each(&Repo.insert!(&1))
  end

  defp update_assignment(student_assignment) do
    case get_assignment_by_ids(student_assignment.assignment_id, student_assignment.student_class_id) do
      nil -> :ok
      assign_old -> StudentAssignment.changeset_update_auto(assign_old, %{name: student_assignment.name,
                                                                      weight_id: student_assignment.weight_id,
                                                                      due: student_assignment.due}) 
                    |> Repo.update
    end
  end
end