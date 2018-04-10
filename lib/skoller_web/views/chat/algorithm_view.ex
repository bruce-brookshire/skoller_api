defmodule SkollerWeb.Chat.AlgorithmView do
  use SkollerWeb, :view

  alias SkollerWeb.Chat.AlgorithmView

  def render("index.json", %{algorithms: algorithms}) do
    render_many(algorithms, AlgorithmView, "algorithm.json")
  end

  def render("algorithm.json", %{algorithm: algorithm}) do
    %{
      id: algorithm.id,
      name: algorithm.name
    }
  end
end
