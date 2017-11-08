defmodule ClassnavapiWeb.Class.IssueView do
  use ClassnavapiWeb, :view

  def render("issue.json", %{issue: issue}) do
    %{
      note: issue.note,
      is_completed: issue.is_completed,
      id: issue.id
    }
  end
end
