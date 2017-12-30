defmodule ClassnavapiWeb.Api.V1.Admin.Class.StatusController do
    use ClassnavapiWeb, :controller

    alias Classnavapi.Class
    alias Classnavapi.Repo
    alias ClassnavapiWeb.ClassView

    import ClassnavapiWeb.Helpers.AuthPlug
    
    @admin_role 200
    
    plug :verify_role, %{role: @admin_role}

    def update(conn, %{"class_id" => class_id, "class_status_id" => id}) do
      class = Repo.get!(Class, class_id)

      results = class
      |> Ecto.Changeset.change(%{class_status_id: id})
      |> Repo.update()

      case results do
        {:ok, class} ->
          render(conn, ClassView, "show.json", class: class)
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
      end
    end
  end