defmodule SkollerWeb.AllView do
  use SkollerWeb, :view

  alias SkollerWeb.AllView

  def render("index.json", %{all: all}) do
    render_many(all, AllView, "all.json")
  end

  def render("show.json", %{all: all}) do
    render_one(all, AllView, "all.json")
  end

  def render("all.json", %{all: all}) do
    all
  end
end
