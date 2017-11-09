defmodule ClassnavapiWeb.Api.V1.Class.HelpRequestController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class
  alias Classnavapi.Class.HelpRequest
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView
  alias ClassnavapiWeb.Class.HelpRequestView
  alias ClassnavapiWeb.Helpers.StatusHelper

  def complete(conn, %{"id" => id}) do
    issue_old = Repo.get!(HelpRequest, id)

    changeset = HelpRequest.changeset(issue_old, %{is_completed: true})

    case Repo.update(changeset) do
      {:ok, issue} ->
        render(conn, HelpRequestView, "show.json", issue: issue)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def create(conn, %{"class_id" => class_id} = params) do

    class = Repo.get!(Class, class_id)
    class = class |> Repo.preload(:class_status)

    changeset = HelpRequest.changeset(%HelpRequest{}, params)
    
    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:help_request, changeset)
    |> Ecto.Multi.run(:class, &StatusHelper.set_help_status(&1, class))

    case Repo.transaction(multi) do
      {:ok, %{class: class}} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, _t1, %Ecto.Changeset{} = changeset, _t2} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
      {:error, _, failed_value, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ErrorView, "error.json", error: failed_value)
    end
  end
end