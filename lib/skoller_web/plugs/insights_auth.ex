defmodule SkollerWeb.Plugs.InsightsAuth do
  alias Skoller.Repo

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

        case resource_exists?(OrgOwner, user_id: user.id, organization_id: organization_id) |> IO.inspect do
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

      verify_role(user, @insights_user_role_id) ->
        if user_owns_org?(user, organization_id) or user_owns_group?(user, group_id) do
          conn
        else
          conn |> unauth
        end

      true ->
        conn |> unauth()
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
    do: from(m in model, where: ^params)
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
    alias Skoller.Organizations.OrgGroupOwners
    OrgGroupOwners.exists?(user_id: id, group_id: group_id)
  end

  defp unauth(conn), do: conn |> send_resp(401, "Unauthorized") |> halt()
end
