defmodule SkollerWeb.Api.V1.Admin.OrganizationController do
  use SkollerWeb, :controller

  alias Skoller.Organizations
  alias Skoller.Organizations.Organization
  alias SkollerWeb.OrganizationView
  alias Skoller.FileUploaders.OrgPics
  alias Ecto.UUID

  import SkollerWeb.Plugs.Auth, only: [verify_role: 2]
  import SkollerWeb.Plugs.InsightsAuth

  @admin_role 200
  @insights_role 700

  action_fallback SkollerWeb.FallbackController

  plug :verify_role,
       %{roles: [@admin_role, @insights_role]} when action in [:show, :update, :delete]

  plug :verify_role, %{role: @admin_role} when action == :create
  plug :verify_owner, :organization when action in [:show, :update, :delete]

  plug :put_view, OrganizationView

  def create(conn, params) do
    with {:ok, %Organization{} = organization} <- Organizations.create_organization(params) do
      conn
      |> put_status(:created)
      |> render("show.json", organization: organization)
    end
  end

  def show(conn, %{"id" => id}) do
    organization = Organizations.get_organization!(id)

    render(conn, "show.json", organization: organization)
  end

  def update(conn, %{"id" => id} = params) do
    id
    |> Organizations.get_organization!()
    |> Organizations.update_organization(upload_pic(params))
    |> case do
      {:ok, %Organization{} = organization} ->
        org = Repo.preload(organization, [school: :class_periods])
        render(conn, "show.json", organization: org)

      _ ->
        send_resp(conn, 422, "Unprocessable input")
    end
  end

  def delete(conn, %{"id" => id}) do
    organization = Organizations.get_organization!(id)

    with {:ok, %Organization{}} <- Organizations.delete_organization(organization) do
      send_resp(conn, :no_content, "")
    end
  end

  defp upload_pic(%{"file" => file} = params) do
    scope = %{"id" => UUID.generate()}

    case OrgPics.store({file, scope}) do
      {:ok, inserted} ->
        location = OrgPics.url({inserted, scope}, :thumb)
        Map.put(params, "logo_url", location)

      _ ->
        nil
    end
  end

  defp upload_pic(params), do: params
end
