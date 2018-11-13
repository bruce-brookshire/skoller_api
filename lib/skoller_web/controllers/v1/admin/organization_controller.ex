defmodule SkollerWeb.Api.V1.Admin.OrganizationController do
  use SkollerWeb, :controller

  alias Skoller.Organizations
  alias Skoller.Organizations.Organization
  alias SkollerWeb.OrganizationView

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  action_fallback SkollerWeb.FallbackController
  plug :verify_role, %{role: @admin_role}

  def create(conn, params) do
    with {:ok, %Organization{} = organization} <- Organizations.create_organization(params) do
      conn
      |> put_status(:created)
      |> render(OrganizationView, "show.json", organization: organization)
    end
  end

  def show(conn, %{"id" => id}) do
    organization = Organizations.get_organization!(id)
    render(conn, OrganizationView, "show.json", organization: organization)
  end

  def update(conn, %{"id" => id} = params) do
    organization = Organizations.get_organization!(id)

    with {:ok, %Organization{} = organization} <- Organizations.update_organization(organization, params) do
      render(conn, OrganizationView, "show.json", organization: organization)
    end
  end

  def delete(conn, %{"id" => id}) do
    organization = Organizations.get_organization!(id)
    with {:ok, %Organization{}} <- Organizations.delete_organization(organization) do
      send_resp(conn, :no_content, "")
    end
  end
end
