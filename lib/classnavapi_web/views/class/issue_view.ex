defmodule ClassnavapiWeb.Class.IssueView do
  use ClassnavapiWeb, :view

  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.Issue.StatusView

  def render("issue.json", %{issue: issue}) do
    issue = issue |> Repo.preload(:class_issue_status)
    %{
      note: issue.note,
      is_completed: issue.is_completed,
      id: issue.id,
      issue_status: render_one(issue.class_issue_status, StatusView, "status.json")
    }
  end
end
