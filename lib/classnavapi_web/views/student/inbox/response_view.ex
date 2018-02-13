defmodule ClassnavapiWeb.Student.Inbox.ResponseView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Student.Inbox.ResponseView
  alias Classnavapi.Repo
  alias Classnavapi.Chat.Reply
  alias Classnavapi.Chat.Comment

  def render("show.json", %{response: response}) do
    render_one(response, ResponseView, "response.json")
  end

  def render("response.json", %{response: %{is_reply: false} = response}) do
    comment = Repo.get!(Comment, response.id) |> Repo.preload(:student)
    %{
      response: response.response,
      is_reply: response.is_reply,
      student: render_one(comment.student, ClassnavapiWeb.StudentView, "student-short.json")
    }
  end

  def render("response.json", %{response: %{is_reply: true} = response}) do
    reply = Repo.get!(Reply, response.id) |> Repo.preload(:student)
    %{
      response: response.response,
      is_reply: response.is_reply,
      student: render_one(reply.student, ClassnavapiWeb.StudentView, "student-short.json")
    }
  end
end