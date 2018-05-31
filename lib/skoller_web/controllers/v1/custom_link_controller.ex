defmodule SkollerWeb.Api.V1.CustomLinkController do
  use SkollerWeb, :controller

  alias Skoller.CustomSignups
  alias SkollerWeb.LinkView

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

end