defmodule SkollerWeb.Student.Inbox.ResponseView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Student.Inbox.ResponseView
  alias Skoller.Repo
  alias Skoller.ChatReplies.Reply
  alias Skoller.ChatComments.Comment

  def render("show.json", %{response: response}) do
    render_one(response, ResponseView, "response.json")
  end

  def render("response.json", %{response: %{is_reply: false} = response}) do
    comment = Repo.get!(Comment, response.id) |> Repo.preload(:student)
    %{
      response: response.response,
      is_reply: response.is_reply,
      inserted_at: comment.inserted_at,
      student: render_one(comment.student, SkollerWeb.StudentView, "student-short.json")
    }
  end

  def render("response.json", %{response: %{is_reply: true} = response}) do
    reply = Repo.get!(Reply, response.id) |> Repo.preload(:student)
    %{
      response: response.response,
      is_reply: response.is_reply,
      inserted_at: reply.inserted_at,
      student: render_one(reply.student, SkollerWeb.StudentView, "student-short.json")
    }
  end
end