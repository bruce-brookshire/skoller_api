defmodule SkollerWeb.Api.V1.Admin.OrganizationController do
  use SkollerWeb, :controller

  alias Skoller.Organizations
  alias Skoller.Organizations.Organization
  alias SkollerWeb.OrganizationView

  import SkollerWeb.Plugs.Auth, only: [verify_role: 2]
  import SkollerWeb.Plugs.InsightsAuth

  @admin_role 200
  @insights_role 700

  action_fallback SkollerWeb.FallbackController
  plug :verify_role, %{roles: [@admin_role, @insights_role]} when action in [:show, :create, :update, :delete]
  plug :verify_owner, :organization
  

  def create(conn, params) do
    with {:ok, %Organization{} = organization} <- Organizations.create_organization(params) do
      conn
      |> put_status(:created)
      |> put_view(OrganizationView)
      |> render("show.json", organization: organization)
    end
  end

  def show(conn, %{"id" => id}) do
    organization = Organizations.get_organization!(id)

    conn
    |> put_view(OrganizationView)
    |> render("show.json", organization: organization)
  end

  def update(conn, %{"id" => id} = params) do
    organization = Organizations.get_organization!(id)

    with {:ok, %Organization{} = organization} <-
           Organizations.update_organization(organization, params) do
      conn
      |> put_view(OrganizationView)
      |> render("show.json", organization: organization)
    end
  end

  def delete(conn, %{"id" => id}) do
    organization = Organizations.get_organization!(id)

    with {:ok, %Organization{}} <- Organizations.delete_organization(organization) do
      send_resp(conn, :no_content, "")
    end
  end
end
