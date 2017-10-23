defmodule ClassnavapiWeb.Api.V1.ClassController do
    use ClassnavapiWeb, :controller
    
    alias Classnavapi.Class
    alias Classnavapi.Repo
    alias ClassnavapiWeb.ClassView
  
    def create(conn, %{} = params) do
  
      changeset = Class.changeset(%Class{}, params)
  
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
  
    def update(conn, params = %{"id" => id}) do
      class_old = Repo.get!(Class, id)
      changeset = Class.changeset(class_old, params)
  
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