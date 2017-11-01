defmodule ClassnavapiWeb.Api.V1.ClassController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class
  alias Classnavapi.Repo
  alias ClassnavapiWeb.ClassView

  def complete(conn, %{"class_id" => id, "is_diy" => true}) do
    class_old = Repo.get!(Class, id)
    changeset = Class.changeset_update(class_old, %{"class_status_id" => 300})

    case Repo.update(changeset) do
      {:ok, class} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def complete(conn, %{"class_id" => id}) do
    class_old = Repo.get!(Class, id)
    changeset = Class.changeset_update(class_old, %{"class_status_id" => 500})

    case Repo.update(changeset) do
      {:ok, class} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def create(conn, %{} = params) do

    changeset = Class.changeset_insert(%Class{}, params)

    case Repo.insert(changeset) do
      {:ok, class} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, _) do
    classes = Repo.all(Class)
    render(conn, ClassView, "index.json", classes: classes)
  end

  def show(conn, %{"id" => id}) do
    class = Repo.get!(Class, id)
    render(conn, ClassView, "show.json", class: class)
  end

  def update(conn, %{"id" => id, "weights" => _} = params) do
    class_old = Repo.get!(Class, id)
    changeset = Class.changeset_update(class_old, params)
    
    changeset = changeset
    |> Ecto.Changeset.change(%{class_status_id: 200})

    case Repo.update(changeset) do
      {:ok, class} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    class_old = Repo.get!(Class, id)
    changeset = Class.changeset_update(class_old, params)

    case Repo.update(changeset) do
      {:ok, class} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end