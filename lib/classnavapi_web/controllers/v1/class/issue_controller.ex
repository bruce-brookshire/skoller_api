defmodule ClassnavapiWeb.Api.V1.Class.IssueController do
    use ClassnavapiWeb, :controller
    
    alias Classnavapi.Class
    alias Classnavapi.Class.Issue
    alias Classnavapi.Repo
    alias ClassnavapiWeb.ClassView

  def create(conn, %{"class_id" => class_id} = params) do

    class = Repo.get!(Class, class_id)

    changeset = Issue.changeset(%Issue{}, params)
    class_changeset = Class.changeset_update(class, %{class_status_id: 400})

    multi = Ecto.Multi.new
            |> Ecto.Multi.insert(:issue, changeset)
            |> Ecto.Multi.update(:class, class_changeset)

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