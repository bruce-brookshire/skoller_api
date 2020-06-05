defmodule SkollerWeb.Plugs.InsightsAuth do
  alias Skoller.Repo

  @student_role_id 100
  @admin_role_id 200
  @insights_user_role_id 700

  import Plug.Conn
  import Ecto.Query

  def verify_owner(
        %{
          assigns: %{user: user},
          params: %{"organization_id" => org_id}
        } = conn,
        :organization
      ) do
    organization_id = org_id |> String.to_integer()

    cond do
      # User is admin
      verify_role(user, @admin_role_id) ->
        conn

      # User is an owner, check ownership
      verify_role(user, @insights_user_role_id) ->
        alias Skoller.Organizations.OrgOwners.OrgOwner

        case resource_exists?(OrgOwner, user_id: user.id, organization_id: organization_id) do
          true -> conn
          false -> conn |> unauth
        end

      # Unauthorized
      true ->
        conn |> unauth
    end
  end

  def verify_owner(
        %{
          assigns: %{user: user},
          params: %{"id" => org_owner_id}
        } = conn,
        :org_owner
      ) do
    alias Skoller.Organizations.OrgOwners.OrgOwner
    org_owner_id = String.to_integer(org_owner_id)

    cond do
      resource_exists?(OrgOwner, org_owner_id, user_id: user.id) -> conn
      true -> unauth(conn)
    end
  end

  def verify_owner(
        %{assigns: %{user: user}, params: %{"organization_id" => org_id} = params} = conn,
        :org_group
      ) do
    organization_id = org_id |> String.to_integer()
    group_id = (params["org_group_id"] || params["id"]) |> String.to_integer()

    cond do
      verify_role(user, @admin_role_id) ->
        conn

      verify_role(user, @insights_user_role_id) and
          (user_owns_org?(user, organization_id) or user_owns_group?(user, group_id)) ->
        conn

      true ->
        conn |> unauth()
    end
  end

  def verify_owner(
        %{
          assigns: %{user: user},
          params: %{"organization_id" => org_id} = params
        } = conn,
        :student_org_invites
      ) do
    organization_id = org_id |> String.to_integer()

    alias Skoller.Organizations.StudentOrgInvitations

    cond do
      verify_role(user, @admin_role_id) ->
        conn

      verify_role(user, @insights_user_role_id) and user_owns_org?(user, organization_id) ->
        conn

      verify_role(user, @student_role_id) and
          invite_exists?(user.student_id, org_id, params["student_org_invitation_id"]) ->
        conn

      true ->
        unauth(conn)
    end
  end

  def verify_owner(
        %{
          assigns: %{user: %{student_id: student_id}},
          params: %{"student_id" => accessing_student_id}
        } = conn,
        :student
      ) do
    if String.to_integer(accessing_student_id) == student_id do
      conn
    else
      conn |> unauth
    end
  end

  defp verify_role(%{roles: roles}, allowable) when is_integer(allowable),
    do: Enum.any?(roles, &(&1.id == allowable))

  defp verify_role(%{roles: roles}, allowable) do
    Enum.any?(roles, fn %{id: role_id} ->
      role_id in allowable
    end)
  end

  defp resource_exists?(model, params) when is_list(params),
    do:
      from(m in model, where: ^params)
      |> Repo.exists?()

  defp resource_exists?(model, id, params) when is_list(params) do
    case Repo.get_by(model, params) do
      %{id: object_id} when object_id == id -> true
      _ -> false
    end
  end

  defp user_owns_org?(%{id: id}, organization_id) do
    alias Skoller.Organizations.OrgOwners
    OrgOwners.exists?(user_id: id, organization_id: organization_id)
  end

  defp user_owns_group?(%{id: id}, group_id) do
    alias Skoller.Organizations.{OrgMembers.OrgMember, OrgGroupOwners.OrgGroupOwner}

    from(m in OrgMember)
    |> join(:inner, [m], o in OrgGroupOwner, on: o.org_member_id == m.id)
    |> where([m, o], m.user_id == ^id and o.org_group_id == ^group_id)
    |> Repo.exists?()
  end

  defp invite_exists?(student_id, org_id, nil) do
    alias Skoller.Organizations.StudentOrgInvitations

    StudentOrgInvitations.exists?(
      organization_id: org_id,
      student_id: student_id
    )
  end

  defp invite_exists?(student_id, org_id, invite_id) do
    alias Skoller.Organizations.StudentOrgInvitations

    StudentOrgInvitations.exists?(
      id: invite_id,
      organization_id: org_id,
      student_id: student_id
    )
  end

  defp unauth(conn), do: conn |> send_resp(401, "Unauthorized") |> halt()
end
