defmodule SkollerWeb.Class.Chat.LikeView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Class.Chat.LikeView

  def render("index.json", %{likes: likes}) do
    render_many(likes, LikeView, "like.json")
  end

  def render("show.json", %{like: like}) do
    render_one(like, LikeView, "like.json")
  end

  def render("like.json", %{like: like}) do
    %{
      id: like.id,
      student_id: like.student_id
    }
  end
end
