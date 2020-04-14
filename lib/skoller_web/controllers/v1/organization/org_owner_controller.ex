defmodule SkollerWeb.Api.V1.Organization.OrgOwnerController do
  use SkollerWeb, :controller

  alias Skoller.Organizations.OrgOwners

  def show(conn, %{"id" => id}) do
    OrgOwners.get_by_id(id) |> IO.inspect()
  end

  # def index(conn, %{"organization_id" => organization_id}) do
  #   conn
  # end

  def create(conn, params) do
    case OrgOwners.create(params) do
      {:ok, owner} ->
        conn
        |> put_view(OrgOwnerView)
        |> render("show.json", owner: owner)

      _ ->
        conn
        |> send_resp(422, "Unprocessable Entity")
    end
  end

  def update(conn, %{"id" => id} = params) do
    case OrgOwners.update(id, params) do
      {:ok, owner} -> 
        conn
        |> put_view(OrgOwnerView)
        |> render("show.json", owner: owner)

      _ -> 
        conn
        |> send_resp(422, "Unprocessable Entity")
    end
  end
end
