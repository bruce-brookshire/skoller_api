defmodule SkollerWeb.Api.V1.CustomLinkController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.CustomSignups
  alias SkollerWeb.LinkView

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def create(conn, params) do
    case params |> CustomSignups.create_link() do
      {:ok, link} ->
        conn
        |> put_view(LinkView)
        |> render("show.json", link: link)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def index(conn, _params) do
    links = CustomSignups.get_links()

    conn
    |> put_view(LinkView)
    |> render("index.json", links: links)
  end

  def update(conn, %{"id" => id} = params) do
    link_old = CustomSignups.get_link_by_id!(id)

    case link_old |> CustomSignups.update_link(params) do
      {:ok, link} ->
        conn
        |> put_view(LinkView)
        |> render("show.json", link: link)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    link = CustomSignups.get_link_by_id!(id)

    conn
    |> put_view(LinkView)
    |> render("show.json", link: link)
  end
end
