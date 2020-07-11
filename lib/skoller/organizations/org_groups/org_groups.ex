defmodule Skoller.Organizations.OrgGroups do
  alias __MODULE__.OrgGroup

  alias Skoller.Organizations.{
    OrgGroupStudents.OrgGroupStudent,
    OrgStudents.OrgStudent,
    StudentOrgInvitations.StudentOrgInvitation
  }

  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Classes.Class
  alias Skoller.Periods.ClassPeriod

  @class_setup_status_id 1400

  use ExMvc.Adapter, model: OrgGroup

  def get_by_id(id), do: id |> super() |> add_metrics()

  def get_by_params(params), do: params |> super() |> add_metrics()

  defp add_metrics(nil), do: nil
  defp add_metrics(enum) when is_list(enum), do: Enum.map(enum, &add_metrics/1)

  defp add_metrics(%OrgGroup{id: org_group_id} = object) do
    # Students and invites with no classes
    students_without_classes =
      OrgGroupStudent
      |> join(:inner, [gs], s in OrgStudent, on: s.id == gs.org_student_id)
      |> join(:left, [gs, s], cs in subquery(students_with_classes_query()),
        on: cs.student_id == s.student_id
      )
      |> where([gs, s, cs], gs.org_group_id == ^org_group_id)
      |> where([gs, s, cs], is_nil(cs.student_id))
      |> Repo.aggregate(:count)

    invites_without_classes =
      StudentOrgInvitation
      |> where(
        [i],
        ^org_group_id in i.group_ids and is_nil(fragment("array_length(?, 1)", i.class_ids))
      )
      |> Repo.aggregate(:count)

    # Students and invites with classes that are not set up
    students_with_not_setup_classes =
      OrgStudent
      |> join(:inner, [s], gs in OrgGroupStudent, on: gs.org_student_id == s.id)
      |> join(:inner, [s, gs], sc in StudentClass, on: s.student_id == sc.student_id)
      |> join(:inner, [s, gs, sc], c in Class, on: c.id == sc.class_id)
      |> join(:inner, [s, gs, sc, c], cp in ClassPeriod, on: cp.id == c.class_period_id)
      |> where([s, gs, sc, c, cp], fragment("current_timestamp < ?", cp.end_date))
      |> where([s, gs, sc, c, cp], sc.is_dropped == false)
      |> where([s, gs, sc, c, cp], c.class_status_id < @class_setup_status_id)
      |> where([s, gs, cp], gs.org_group_id == ^org_group_id)
      |> distinct([s, gs, sc, c, cp], s.id)
      |> Repo.aggregate(:count)

    invites_with_not_setup_classes =
      from(i in StudentOrgInvitation)
      |> join(:inner, [i], c in Class, on: c.id in i.class_ids)
      |> join(:inner, [i, c], cp in ClassPeriod, on: cp.id == c.class_period_id)
      |> where([i, c, cp], fragment("current_timestamp < ?", cp.end_date))
      |> where([i, c, cp], c.class_status_id < @class_setup_status_id)
      |> where([i, c, cp], ^org_group_id in i.group_ids)
      |> distinct([i, c, cp], i.id)
      |> Repo.aggregate(:count)

    # Unaccepted invitations
    invites =
      StudentOrgInvitation
      |> where([i], ^org_group_id in i.group_ids)
      |> Repo.aggregate(:count)

    metrics = %{
      unresponded_invitation_count: invites,
      students_with_classes_not_setup_count:
        students_with_not_setup_classes + invites_with_not_setup_classes,
      students_with_no_classes_count: students_without_classes + invites_without_classes
    }

    Map.put(object, :metrics, metrics)
  end

  defp students_with_classes_query(),
    do:
      StudentClass
      |> join(:inner, [sc], c in Class, on: c.id == sc.class_id)
      |> join(:inner, [sc, c], cp in ClassPeriod, on: cp.id == c.class_period_id)
      |> where([sc, c, cp], fragment("current_timestamp < ?", cp.end_date))
      |> where([sc, c, cp], sc.is_dropped == false)
      |> distinct([sc, c, cp], sc.student_id)
      |> select([sc, c, cp], %{student_id: sc.student_id})
end
