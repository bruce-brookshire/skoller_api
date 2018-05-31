defmodule SkollerWeb.LinkView do
  use SkollerWeb, :view

  alias SkollerWeb.LinkView

  def render("index.json", %{links: links}) do
    render_many(links, LinkView, "link.json")
  end

  def render("show.json", %{link: link}) do
    render_one(link, LinkView, "link.json")
  end

  def render("link.json", %{link: link}) do
    %{
      id: link.id,
      name: link.name,
      link: link.link,
      start_date: link.start,
      end_date: link.end
    }
  end
end
