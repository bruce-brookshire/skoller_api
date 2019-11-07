defmodule SkollerWeb.Api.V1.SessionController do
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias Skoller.Sessions
  alias SkollerWeb.SessionView

  def create(conn, params) do
    case Sessions.insert(params) do
      {:ok, session} ->
        session = session |> Repo.preload([:session_platform])

        conn
        |> put_view(SessionView)
        |> render("show.json", session: session)

      {:error, _} ->
        conn |> send_resp(422, "Unable to create session")
    end
  end
end
