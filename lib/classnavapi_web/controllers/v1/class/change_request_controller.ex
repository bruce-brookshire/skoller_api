defmodule ClassnavapiWeb.Api.V1.Class.ChangeRequestController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class
  alias Classnavapi.Class.ChangeRequest
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView
  alias ClassnavapiWeb.Class.ChangeRequestView
  alias ClassnavapiWeb.Helpers.StatusHelper

  def complete(conn, %{"id" => id}) do
    change_request_old = Repo.get!(ChangeRequest, id)

    changeset = ChangeRequest.changeset(change_request_old, %{is_completed: true})

    case Repo.update(changeset) do
      {:ok, change_request} ->
        render(conn, ChangeRequestView, "show.json", change_request: change_request)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def create(conn, %{"class_id" => class_id} = params) do

    class = Repo.get!(Class, class_id)
    class = class |> Repo.preload(:class_status)

    changeset = ChangeRequest.changeset(%ChangeRequest{}, params)
    
    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:change_request, changeset)
    |> Ecto.Multi.run(:class, &StatusHelper.set_change_status(&1, class))

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