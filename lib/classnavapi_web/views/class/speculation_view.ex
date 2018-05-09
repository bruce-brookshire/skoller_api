defmodule ClassnavapiWeb.Class.SpeculationView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.SpeculationView

  def render("index.json", %{speculations: speculations}) do
    render_many(speculations, SpeculationView, "speculation.json")
  end

  def render("show.json", %{speculation: speculation}) do
    render_one(speculation, SpeculationView, "speculation.json")
  end

  def render("speculation.json", %{speculation: speculation}) do
    %{
      grade: speculation.grade,
      speculation: Decimal.to_float(Decimal.round(speculation.speculation, 2))
    }
  end
end
  