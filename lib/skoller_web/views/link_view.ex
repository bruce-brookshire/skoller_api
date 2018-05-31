defmodule SkollerWeb.LinkView do
  use SkollerWeb, :view

  alias SkollerWeb.LinkView

  @custom_signup_path "/c/"

  def render("index.json", %{links: links}) do
    render_many(links, LinkView, "link.json")
  end

  def render("show.json", %{link: link}) do
    render_one(link, LinkView, "link_detail.json")
  end

  def render("link.json", %{link: link}) do
    %{
      id: link.link.id,
      name: link.link.name,
      link: System.get_env("WEB_URL") <> @custom_signup_path <> link.link.link,
      start_date: link.link.start,
      end_date: link.link.end,
      signup_count: link.signup_count
    }
  end

  def render("link_detail.json", %{link: link}) do
    %{
      id: link.id,
      name: link.name,
      link: System.get_env("WEB_URL") <> @custom_signup_path <> link.link,
      start_date: link.start,
      end_date: link.end
    }
  end
end
