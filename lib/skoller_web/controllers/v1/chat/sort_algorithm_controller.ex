defmodule SkollerWeb.Api.V1.Chat.SortAlgorithmController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Chat.AlgorithmView
  alias Skoller.Chats

  def index(conn, _params) do
    algorithms = Chats.get_algorithms()

    conn
    |> put_view(AlgorithmView)
    |> render("index.json", algorithms: algorithms)
  end
end
