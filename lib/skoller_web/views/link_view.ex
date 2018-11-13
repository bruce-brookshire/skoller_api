defmodule SkollerWeb.LinkView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.LinkView
  alias Skoller.Repo
  alias SkollerWeb.StudentView

  @custom_signup_path "/c/"

  def render("index.json", %{links: links}) do
    render_many(links, LinkView, "link.json")
  end

  def render("show.json", %{link: link}) do
    render_one(link, LinkView, "link_detail.json")
  end

  def render("link.json", %{link: link}) do
    render_one(link.link, LinkView, "link_base.json")
    |> Map.merge(%{
      signup_count: link.signup_count
    })
  end

  def render("link_base.json", %{link: link}) do
    %{
      id: link.id,
      name: link.name,
      link: System.get_env("WEB_URL") <> @custom_signup_path <> link.link,
      start_date: link.start,
      end_date: link.end
    }
  end

  def render("link_detail.json", %{link: link}) do
    link = link |> Repo.preload(:students)
    render_one(link, LinkView, "link_base.json")
    |> Map.merge(%{
      students: render_many(link.students, StudentView, "student-short.json")
    })
  end
end
