defmodule Skoller.Organizations.StudentOrgInvitations do
  use ExMvc.Adapter, model: __MODULE__.StudentOrgInvitation

  alias Skoller.StudentClasses
  alias Skoller.Classes.Class
  alias Skoller.Assignments.Mods

  def get_by_params(query_params) when is_map(query_params) do
    fields = Model.__schema__(:fields) |> Enum.map(&to_string/1)

    query_params
    |> Map.take(fields)
    |> Enum.map(fn {key, val} -> {String.to_atom(key), val} end)
    |> get_by_params()
  end

  def get_by_params(query_params) when is_list(query_params) do
    from(m in Model, where: ^query_params)
    |> Repo.all()
    |> Enum.map(&preload/1)
    |> Enum.map(&fetch_invite_assignments/1)
    |> IO.inspect()
  end

  defp fetch_invite_assignments(%{class_ids: class_ids} = invite) do
    cl =
      class_ids
      |> Enum.reduce(Class, fn elem, q ->
        or_where(q, [c], c.id == ^elem)
      end)
      |> Ecto.Query.preload([:weights, :notes])
      |> Repo.all()
      |> IO.inspect
      |> Enum.map(fn %{id: id} = class ->
        class
        |> Map.put(:assignments, Mods.get_mod_assignments_by_class(id))
        |> Map.put(:students, StudentClasses.get_studentclasses_by_class(id))
        |> IO.inspect
      end)

    %{invite | classes: cl}
  end

  def convert_invite_to_student(student_id, phone) do
    StudentOrgInvitation
    |> Repo.get_by(phone: phone)
    |> case do
      nil -> {:ok, "Student does not exist"}
      %{} = invitation -> __MODULE__.update(invitation, %{student_id: student_id})
    end
  end

  def get_invitations_by_org_group(org_group_id) do
    StudentOrgInvitation
    |> where([i], ^org_group_id in i.group_ids)
    |> preload([:organization])
    |> Repo.all()
  end
end
