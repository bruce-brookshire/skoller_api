defmodule Skoller.Assignments.Mods do
  @moduledoc """
  Context module for mods
  """

  alias Skoller.Assignment.Mod
  alias Skoller.Assignment.Mod.Action
  alias Skoller.Class.StudentClass
  alias Skoller.Class.StudentAssignment
  alias Skoller.Repo
  alias Skoller.Class.Assignment
  alias Skoller.Students
  alias Skoller.Schools.Class
  alias Skoller.Users.User
  alias Skoller.Students.Student

  import Ecto.Query

  @due_assignment_mod 300
  @new_assignment_mod 400

  @doc """
  Gets all the mods for an assignment.

  Returns `[Skoller.Assignment.Mod]` with mod action details or `[]`
  """
  def get_mods_by_assignment(assignment_id) do
    from(m in Mod)
    |> where([m], m.assignment_id == ^assignment_id)
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :action, add_action_details(&1.id)))
  end

  @doc """
  Gets all the mods for a student that are due today or in the future.

  ## Params
   * `%{"is_new_assignments" => "true"}`, :boolean, returns only new assignment mods for a student

  ## Returns
  `[%{mod: Skoller.Assignment.Mod, action: Skoller.Assignment.Mod.Action, 
  student_assignment: Skoller.Class.StudentAssignment}]` or `[]`
  """
  def get_student_mods(student_id, params \\ %{}) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, action.assignment_modification_id == mod.id)
    |> join(:inner, [mod, action], sc in StudentClass, sc.id == action.student_class_id)
    |> join(:left, [mod, action, sc], sa in StudentAssignment, sc.id == sa.student_class_id and mod.assignment_id == sa.assignment_id)
    |> where([mod, action, sc, sa], sc.student_id == ^student_id and sc.is_dropped == false)
    |> where([mod, action, sc, sa], (mod.assignment_mod_type_id not in [@new_assignment_mod] and not is_nil(sa.id)) or (is_nil(sa.id) and mod.assignment_mod_type_id in [@new_assignment_mod]))
    |> filter(params)
    |> select([mod, action, sc, sa], %{mod: mod, action: action, student_assignment: sa})
    |> Repo.all()
    |> Enum.filter(&filter_due_date(&1, DateTime.utc_now()))
  end

  @doc """
  Gets a mod by student id and mod id.

  Student must still be enrolled in class.

  ## Returns
  `%{mod: Skoller.Assignment.Mod, action: Skoller.Assignment.Mod.Action, 
  student_assignment: Skoller.Class.StudentAssignment}`, `nil`, or raises if more than one
  """
  def get_student_mod_by_id(student_id, mod_id) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, action.assignment_modification_id == mod.id)
    |> join(:inner, [mod, action], sc in subquery(Students.get_enrolled_classes_by_student_id_subquery(student_id)), sc.id == action.student_class_id)
    |> join(:left, [mod, action, sc], sa in StudentAssignment, sc.id == sa.student_class_id and mod.assignment_id == sa.assignment_id)
    |> where([mod, action, sc, sa], (mod.assignment_mod_type_id not in [@new_assignment_mod] and not is_nil(sa.id)) or (is_nil(sa.id) and mod.assignment_mod_type_id in [@new_assignment_mod]))
    |> where([mod], mod.id == ^mod_id)
    |> select([mod, action, sc, sa], %{mod: mod, action: action, student_assignment: sa})
    |> Repo.one()
  end

  @doc """
  Gets assignments with mod count and student count by class id.

  ## Returns
  `[%{assignment: %{assignment: Skoller.Class.Assignment, mod_count: Integer, student_count: Integer}}]` or `[]`
  """
  def get_mod_assignments_by_class(class_id) do
    from(a in Assignment)
    |> join(:left, [a], m in Mod, m.assignment_id == a.id)
    |> join(:left, [a], s in StudentAssignment, s.assignment_id == a.id)
    |> where([a], a.class_id == ^class_id)
    |> group_by([a], a.id)
    |> select([a, m, s], %{assignment: %{assignment: a, mod_count: count(m.id), student_count: count(s.id)}})
    |> Repo.all()
  end

  @doc """
  Gets the class from a mod id

  ## Returns
  `Skoller.Schools.Class`, `nil` or raises if more than one.
  """
  def get_class_from_mod_id(mod_id) do
    from(class in Class)
    |> join(:inner, [class], assign in Assignment, class.id == assign.class_id)
    |> join(:inner, [class, assign], mod in Mod, mod.assignment_id == assign.id)
    |> where([class, assign, mod], mod.id == ^mod_id)
    |> Repo.one()
  end

  @doc """
  Subquery to associate Mods and Classes easily.

  Intended to be used with `Ecto.Query.subquery/1`

  ## Returns
  `Ecto.Query` with `%{class_id: id, mod_id: id}`
  """
  def get_class_from_mod_subquery() do
    from(mod in Mod)
    |> join(:inner, [mod], assign in Assignment, mod.assignment_id == assign.id)
    |> select([mod, assign], %{class_id: assign.class_id, mod_id: mod.id})
  end

  @doc """
  Gets the enrolled classes that a student has pending mods in.

  ## Returns
  `[Skoller.Schools.Class]` or `[]`
  """
  def get_classes_with_pending_mod_by_student_id(student_id) do
    from(class in Class)
    |> join(:inner, [class], sc in subquery(Students.get_enrolled_classes_by_student_id_subquery(student_id)), sc.class_id == class.id)
    |> join(:inner, [class, sc], act in Action, act.student_class_id == sc.id)
    |> where([class, sc, act], is_nil(act.is_accepted))
    |> Repo.all()
  end

  @doc """
  Gets the count of joyriders.

  Joyriders are students in communities that have autoupdated mods.

  ## Returns
  `Integer`
  """
  def get_joyriders() do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(Students.get_communities()), cm.class_id == sc.class_id)
    |> where([a], a.is_accepted == true and a.is_manual == false)
    |> distinct([a, sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the count of pending students.

  Pending students are students in communities with mods that they have not responded to yet.

  ## Returns
  `Integer`
  """
  def get_pending() do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(Students.get_communities()), cm.class_id == sc.class_id)
    |> where([a], is_nil(a.is_accepted))
    |> distinct([a, sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the count of followers.

  Followers are students in communities with mods that they accepted.

  ## Returns
  `Integer`
  """
  def get_followers() do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(Students.get_communities()), cm.class_id == sc.class_id)
    |> where([a], a.is_manual == true and a.is_accepted == true)
    |> distinct([a, sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the count of creators.

  Creators are students in communities that creates a mod.

  ## Returns
  `Integer`
  """
  def get_creators() do
    from(m in Mod)
    |> join(:inner, [m], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.student_id == m.student_id)
    |> join(:inner, [m, sc], cm in subquery(Students.get_communities()), cm.class_id == sc.class_id)
    |> distinct([m], m.student_id)
    |> Repo.aggregate(:count, :id)
  end

  # @doc """
  # Gets public mods that have at least one response as well as the accepted and response count.

  # ## Returns
  # `[%{mod: Skoller.Assignment.Mod, responses: Integer, accepted: Integer}]` or `[]`
  # """
  def get_responded_mods() do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> join(:inner, [m, a], sc in subquery(Students.get_communities()), sc.class_id == a.class_id)
    |> join(:inner, [m, a, sc], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> where([m], m.is_private == false)
    |> where([m], fragment("exists(select 1 from modification_actions ma inner join student_classes sc on sc.id = ma.student_class_id where sc.is_dropped = false and ma.is_accepted = true and ma.assignment_modification_id = ? and sc.student_id != ?)", m.id, m.student_id)) #Get mods with a response that is not from the creator.
    |> select([m, a, sc, act], %{mod: m, responses: act.responses, accepted: act.accepted})
    |> Repo.all()
  end

  @doc """
  Gets avatar urls for students who accepted a given mod.

  ## Returns
  `[String]` or `[]`
  """
  def get_student_pic_by_mod_acceptance(mod_id) do
    from(user in User)
    |> join(:inner, [user], stu in Student, user.student_id == stu.id)
    |> join(:inner, [user, stu], sc in StudentClass, sc.student_id == stu.id)
    |> join(:inner, [user, stu, sc], act in Action, act.student_class_id == sc.id)
    |> where([user, stu, sc, act], act.assignment_modification_id == ^mod_id)
    |> where([user, stu, sc, act], act.is_accepted == true)
    |> select([user, stu, sc, act], user.pic_path)
    |> Repo.all()
  end

  # @doc """
  # Gets public mods that have at least one response as well as the accepted and response count.

  # ## Returns
  # `[%{mod: Skoller.Assignment.Mod, responses: Integer, audience: Integer}]` or `[]`
  # """
  def get_shared_mods() do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> join(:inner, [m, a], sc in subquery(Students.get_communities()), sc.class_id == a.class_id)
    |> join(:inner, [m, a, sc], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> where([m], m.is_private == false)
    |> select([m, a, sc, act], %{mod: m, responses: act.responses, audience: act.audience})
    |> Repo.all()
  end

  # @doc """
  # Gets public mods that have not been auto updated, but have enough students to be auto updated.
  #
  # ## Returns
  # `[%{assignment_modification_id: Id, responses: Integer, audience: Integer, accepted: Integer}]` or `[]`
  # """
  def get_non_auto_update_mods_in_enrollment_threshold(enrollment_threshold) do
    from(m in Mod)
    |> join(:inner, [m], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> join(:inner, [m, act], a in Assignment, a.id == m.assignment_id)
    |> where([m], m.is_auto_update == false and m.is_private == false)
    |> where([m, act, a], fragment("exists (select 1 from student_classes sc where sc.class_id = ? and sc.is_dropped = false group by class_id having count(1) > ?)", a.class_id, ^enrollment_threshold))
    |> select([m, act], act)
    |> Repo.all()
  end

  defp filter(query, params) do
    query
    |> filter_new_assign_mods(params)
  end

  defp filter_new_assign_mods(query, %{"is_new_assignments" => "true"}) do
    query
    |> where([mod], mod.assignment_mod_type_id == @new_assignment_mod)
  end
  defp filter_new_assign_mods(query, _params), do: query

  #This is a subquery that returns the responses for a mod of all enrolled students in that class.
  defp mod_responses_sub() do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.id == a.student_class_id)
    |> group_by([a], a.assignment_modification_id)
    |> select([a], %{assignment_modification_id: a.assignment_modification_id, responses: count(a.is_accepted), audience: count(a.id), accepted: sum(fragment("?::int", a.is_accepted))})
  end

  #This gets enrolled users' Skoller.Assignment.Mod.Action and Skoller.Users.User for a given mod.
  defp add_action_details(mod_id) do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(Students.get_enrolled_student_classes_subquery()), a.student_class_id == sc.id)
    |> join(:inner, [a, sc], s in Student, s.id == sc.student_id)
    |> join(:inner, [a, sc, s], u in User, u.student_id == s.id)
    |> where([a], a.assignment_modification_id == ^mod_id)
    |> select([a, sc, s, u], %{action: a, user: u})
    |> Repo.all()
  end

  defp filter_due_date(%{mod: %{assignment_mod_type_id: @due_assignment_mod} = mod}, date) do
    {:ok, mod_date, _} = DateTime.from_iso8601(mod.data["due"])
    case DateTime.compare(date, mod_date) do
      :gt -> false
      _ -> true
    end
  end
  defp filter_due_date(_mod, _date), do: true
end