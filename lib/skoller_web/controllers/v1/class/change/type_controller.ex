defmodule SkollerWeb.Api.V1.Class.Change.TypeController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.ChangeRequests
  alias SkollerWeb.Class.Change.TypeView

  def index(conn, _) do
    types = ChangeRequests.get_types()

    conn
    |> put_view(TypeView)
    |> render("index.json", types: types)
  end
end
