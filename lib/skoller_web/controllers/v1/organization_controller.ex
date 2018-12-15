defmodule SkollerWeb.Api.V1.OrganizationController do
  use SkollerWeb, :controller

  alias Skoller.Organizations
  alias SkollerWeb.OrganizationView

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200

  action_fallback SkollerWeb.FallbackController
  plug :verify_role, %{roles: [@admin_role, @student_role]}

  def index(%{assigns: %{user: user}} = conn, _params) do
    is_admin = user.roles |> Enum.any?(& &1.id == @admin_role)

    organizations = Organizations.list_organizations()

    case is_admin do
      true -> render(conn, OrganizationView, "index-admin.json", organizations: organizations)
      false -> render(conn, OrganizationView, "index.json", organizations: organizations)
    end
  end
end
