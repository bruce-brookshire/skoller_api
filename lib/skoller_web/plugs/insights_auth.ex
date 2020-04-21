defmodule SkollerWeb.Plugs.InsightsAuth do
  alias Skoller.Users
  alias Skoller.Organizations.OrgOwners
  alias Skoller.Repo

  @admin_role_id 200
  @org_owner_role_id 700

  import Plug.Conn

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
      verify_role(user.roles, @admin_role_id) ->
        conn

      # User is an owner, check ownership
      verify_role(user.roles, @org_owner_role_id) ->
        user_owns_org(conn, user, organization_id)

      # Unauthorized
      true ->
        conn |> unauthorized
    end
  end

  def verify_owner(%{} = conn, :org_group) do
    conn
  end

  defp verify_role(roles, allowable) when is_integer(allowable),
    do: Enum.any?(roles, &(&1.id == allowable))

  defp verify_role(roles, allowable) do
    Enum.any?(roles, fn %{id: role_id} ->
      role_id in allowable
    end)
  end

  defp user_owns_org(conn, %{id: id}, organization_id) do
    OrgOwners.index(user_id: id)
    |> Enum.any?(&(&1.organization_id == organization_id))
    |> case do
      true -> conn
      false -> conn |> unauthorized
    end
  end

  defp unauthorized(conn), do: conn |> send_resp(401, "Unauthorized") |> halt()
end
