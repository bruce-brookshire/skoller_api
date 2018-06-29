defmodule SkollerWeb.Class.SpeculationView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Class.SpeculationView

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
  