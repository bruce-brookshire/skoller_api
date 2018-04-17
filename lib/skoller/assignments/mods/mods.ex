defmodule Skoller.Assignments.Mods do

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

  def get_student_mod_by_id(student_id, mod_id) do
    from(mod in Mod)
    |> join(:inner, [mod], action in Action, action.assignment_modification_id == mod.id)
    |> join(:inner, [mod, action], sc in StudentClass, sc.id == action.student_class_id)
    |> join(:left, [mod, action, sc], sa in StudentAssignment, sc.id == sa.student_class_id and mod.assignment_id == sa.assignment_id)
    |> where([mod, action, sc, sa], sc.student_id == ^student_id and sc.is_dropped == false)
    |> where([mod, action, sc, sa], (mod.assignment_mod_type_id not in [@new_assignment_mod] and not is_nil(sa.id)) or (is_nil(sa.id) and mod.assignment_mod_type_id in [@new_assignment_mod]))
    |> where([mod], mod.id == ^mod_id)
    |> select([mod, action, sc, sa], %{mod: mod, action: action, student_assignment: sa})
    |> Repo.one()
  end

  def get_class_from_mod_id(id) do
    from(class in Class)
    |> join(:inner, [class], assign in Assignment, class.id == assign.class_id)
    |> join(:inner, [class, assign], mod in Mod, mod.assignment_id == assign.id)
    |> where([class, assign, mod], mod.id == ^id)
    |> Repo.one()
  end

  def get_class_from_mod_subquery() do
    from(mod in Mod)
    |> join(:inner, [mod], assign in Assignment, mod.assignment_id == assign.id)
    |> select([mod, assign], %{class_id: assign.class_id, mod_id: mod.id})
  end

  def get_classes_with_pending_mod_by_student_id(student_id) do
    from(class in Class)
    |> join(:inner, [class], sc in subquery(Students.get_enrolled_classes_by_student_id_subquery(student_id)), sc.class_id == class.id)
    |> join(:inner, [class, sc], act in Action, act.student_class_id == sc.id)
    |> where([class, sc, act], is_nil(act.is_accepted))
    |> Repo.all()
  end

  def get_joyriders() do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(Students.get_communities()), cm.class_id == sc.class_id)
    |> where([a], a.is_accepted == true and a.is_manual == false)
    |> distinct([a, sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  def get_pending() do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(Students.get_communities()), cm.class_id == sc.class_id)
    |> where([a], is_nil(a.is_accepted))
    |> distinct([a, sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  def get_followers() do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.id == a.student_class_id)
    |> join(:inner, [a, sc], cm in subquery(Students.get_communities()), cm.class_id == sc.class_id)
    |> where([a], a.is_manual == true and a.is_accepted == true)
    |> distinct([a, sc], sc.student_id)
    |> Repo.aggregate(:count, :id)
  end

  def get_creators() do
    from(m in Mod)
    |> join(:inner, [m], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.student_id == m.student_id)
    |> join(:inner, [m, sc], cm in subquery(Students.get_communities()), cm.class_id == sc.class_id)
    |> distinct([m], m.student_id)
    |> Repo.aggregate(:count, :id)
  end

  def get_responded_mods() do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> join(:inner, [m, a], sc in subquery(Students.get_communities()), sc.class_id == a.class_id)
    |> join(:inner, [m, a, sc], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> where([m], m.is_private == false)
    |> where([m], fragment("exists(select 1 from modification_actions ma inner join student_classes sc on sc.id = ma.student_class_id where sc.is_dropped = false and ma.is_accepted = true and ma.assignment_modification_id = ? and sc.student_id != ?)", m.id, m.student_id))
    |> select([m, a, sc, act], %{mod: m, responses: act.responses, accepted: act.accepted})
    |> Repo.all()
  end

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

  def get_shared_mods() do
    from(m in Mod)
    |> join(:inner, [m], a in Assignment, m.assignment_id == a.id)
    |> join(:inner, [m, a], sc in subquery(Students.get_communities()), sc.class_id == a.class_id)
    |> join(:inner, [m, a, sc], act in subquery(mod_responses_sub()), act.assignment_modification_id == m.id)
    |> where([m], m.is_private == false)
    |> select([m, a, sc, act], %{mod: m, responses: act.responses, audience: act.audience})
    |> Repo.all()
  end

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

  defp mod_responses_sub() do
    from(a in Action)
    |> join(:inner, [a], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.id == a.student_class_id)
    |> group_by([a], a.assignment_modification_id)
    |> select([a], %{assignment_modification_id: a.assignment_modification_id, responses: count(a.is_accepted), audience: count(a.id), accepted: sum(fragment("?::int", a.is_accepted))})
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