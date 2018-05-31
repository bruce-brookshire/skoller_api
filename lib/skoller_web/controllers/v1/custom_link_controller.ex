defmodule SkollerWeb.Api.V1.CustomLinkController do
  use SkollerWeb, :controller

  alias Skoller.CustomSignups
  alias SkollerWeb.LinkView

  import SkollerWeb.Helpers.AuthPlug
  
  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def create(conn, params) do
    case params |> CustomSignups.create_link() do
      {:ok, link} ->
        render(conn, LinkView, "show.json", link: link)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, _params) do
    links = CustomSignups.get_links()
    render(conn, LinkView, "index.json", links: links)
  end

  def update(conn, %{"id" => id} = params) do
    link_old = CustomSignups.get_link_by_id(id)
    case link_old |> CustomSignups.update_link(params) do
      {:ok, link} ->
        render(conn, LinkView, "show.json", link: link)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    link = CustomSignups.get_link_by_id(id)
    render(conn, LinkView, "show.json", link: link)
  end
end