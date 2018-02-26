defmodule ClassnavapiWeb.Api.V1.Chat.SortAlgorithmController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Chat.AlgorithmView
  alias Classnavapi.Chat.Algorithm

  def index(conn, _params) do
    algorithms = Repo.all(Algorithm)
    render(conn, AlgorithmView, "index.json", algorithms: algorithms)
  end
end