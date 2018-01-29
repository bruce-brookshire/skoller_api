defmodule ClassnavapiWeb.Api.V1.Admin.Class.StatusController do
    use ClassnavapiWeb, :controller

    alias Classnavapi.Class
    alias Classnavapi.Class.Status
    alias Classnavapi.Repo
    alias ClassnavapiWeb.ClassView

    import ClassnavapiWeb.Helpers.AuthPlug
    
    @admin_role 200
    
    plug :verify_role, %{role: @admin_role}

    def update(conn, %{"class_id" => class_id, "class_status_id" => id}) do
      class = Repo.get!(Class, class_id)
      |> Repo.preload(:class_status)

      status = Repo.get!(Status, id)

      changeset = class
      |> Ecto.Changeset.change(%{class_status_id: id})
      |> compare_class_status_completion(class.class_status.is_complete, status.is_complete)

      case Repo.update(changeset) do
        {:ok, class} ->
          render(conn, ClassView, "show.json", class: class)
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
      end
    end

    defp compare_class_status_completion(changeset, true, false) do
      changeset
      |> Ecto.Changeset.add_error(:class_status_id, "Class status moving from complete to incomplete")
    end
    defp compare_class_status_completion(changeset, _, _), do: changeset
  end