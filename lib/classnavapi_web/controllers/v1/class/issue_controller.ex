defmodule ClassnavapiWeb.Api.V1.Class.IssueController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class
  alias Classnavapi.Class.Issue
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView
  alias ClassnavapiWeb.Class.IssueView
  alias ClassnavapiWeb.Helpers.StatusHelper

  def complete(conn, %{"id" => id}) do
    issue_old = Repo.get!(Issue, id)

    changeset = Issue.changeset(issue_old, %{is_completed: true})

    case Repo.update(changeset) do
      {:ok, issue} ->
        render(conn, IssueView, "show.json", issue: issue)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def create(conn, %{"class_id" => class_id} = params) do

    class = Repo.get!(Class, class_id)
    class = class |> Repo.preload([:class_status, :class_period, :issues])

    changeset = Issue.changeset(%Issue{}, params)

    multi = Ecto.Multi.new
            |> Ecto.Multi.insert(:issue, changeset)
            |> Ecto.Multi.run(:class, &StatusHelper.set_help_status(&1, class))

    case Repo.transaction(multi) do
      {:ok, %{class: class}} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, _, failed_value, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: failed_value)
    end
  end
end