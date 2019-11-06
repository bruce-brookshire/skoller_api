defmodule SkollerWeb.Api.V1.SessionController do
  use SkollerWeb, :controller

  alias Skoller.Sessions
  alias SkollerWeb.SessionView

  def create(conn, params) do
    case Sessions.insert(params) do
      {:ok, session} ->
        conn
        |> put_view(SessionView)
        |> render("show.json", session: session)
      {:error, session} -> 
        conn |> send_resp(422, "Unable to create session")
    end
  end
end
