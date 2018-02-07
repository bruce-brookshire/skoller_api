defmodule ClassnavapiWeb.Api.V1.Admin.Class.StatusController do
    use ClassnavapiWeb, :controller

    alias Classnavapi.Class
    alias Classnavapi.Class.Status
    alias Classnavapi.Repo
    alias ClassnavapiWeb.ClassView
    alias Classnavapi.Class.Lock
    alias ClassnavapiWeb.Helpers.RepoHelper

    import ClassnavapiWeb.Helpers.AuthPlug
    import Ecto.Query
    
    @admin_role 200
    @help_status 600

    @assignment_status 400
    @review_status 500
    @help_status 600

    @weight_lock 100
    @assignment_lock 200
    @review_lock 300
    
    plug :verify_role, %{roles: [@admin_role, @help_status]}

    def update(conn, %{"class_id" => class_id, "class_status_id" => id}) do
      class = Repo.get!(Class, class_id)
      |> Repo.preload(:class_status)

      status = Repo.get!(Status, id)

      changeset = class
      |> Ecto.Changeset.change(%{class_status_id: id})
      |> compare_class_status_completion(class.class_status.is_complete, status.is_complete)

      multi = Ecto.Multi.new()
      |> Ecto.Multi.update(:class, changeset)
      |> Ecto.Multi.run(:class_locs, &reset_locks(&1.class, status))

      case Repo.transaction(multi) do
        {:ok, %{class: class}} ->
          render(conn, ClassView, "show.json", class: class)
        {:error, _, failed_value, _} ->
          conn
          |> RepoHelper.multi_error(failed_value)
      end
    end

    defp reset_locks(_class, %{is_complete: true}), do: {:ok, nil}
    defp reset_locks(%{class_status_id: @help_status}, _status), do: {:ok, nil}
    defp reset_locks(class, _status) do
      case class.class_status_id do
        @review_status -> 
          {:ok, delete_locks(class, @review_lock)}
        @assignment_status ->
          {:ok, delete_locks(class, @assignment_lock)}
        _ ->
          {:ok, delete_locks(class, @weight_lock)}
      end
    end

    defp delete_locks(class, lock_type_min) do
      from(l in Lock)
      |> where([l], l.class_id == ^class.id and l.class_lock_section_id >= ^lock_type_min)
      |> Repo.delete_all()
    end

    defp compare_class_status_completion(changeset, true, false) do
      changeset
      |> Ecto.Changeset.add_error(:class_status_id, "Class status moving from complete to incomplete")
    end
    defp compare_class_status_completion(changeset, _, _), do: changeset
  end