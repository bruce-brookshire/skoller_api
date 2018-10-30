defmodule SkollerWeb.Api.V1.Chat.SortAlgorithmController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias SkollerWeb.Chat.AlgorithmView
  alias Skoller.Chats

  def index(conn, _params) do
    algorithms = Chats.get_algorithms()
    render(conn, AlgorithmView, "index.json", algorithms: algorithms)
  end
end