defmodule SkollerWeb.Api.V1.Chat.SortAlgorithmController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias SkollerWeb.Chat.AlgorithmView
  alias Skoller.Chats.Algorithm

  def index(conn, _params) do
    algorithms = Repo.all(Algorithm)
    render(conn, AlgorithmView, "index.json", algorithms: algorithms)
  end
end