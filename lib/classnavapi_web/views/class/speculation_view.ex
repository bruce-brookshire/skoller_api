defmodule ClassnavapiWeb.Class.SpeculationView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.SpeculationView

  def render("show.json", %{speculation: speculation}) do
    render_one(speculation, SpeculationView, "speculation.json")
  end

  def render("speculation.json", %{speculation: speculation}) do
    %{
      speculation: Decimal.to_float(speculation)
    }
  end
end
  