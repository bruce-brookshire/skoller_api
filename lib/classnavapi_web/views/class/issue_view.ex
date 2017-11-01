defmodule ClassnavapiWeb.Class.IssueView do
    use ClassnavapiWeb, :view
  
    alias ClassnavapiWeb.Class.IssueView
  
    def render("index.json", %{issues: issues}) do
      render_many(issues, IssueView, "issue.json")
    end
  
    def render("show.json", %{issue: issue}) do
      render_one(issue, IssueView, "issue.json")
    end
  
    def render("issue.json", %{issue: issue}) do
        status = Classnavapi.Repo.get!(Class)
      %{
        
      }
    end
  end
  