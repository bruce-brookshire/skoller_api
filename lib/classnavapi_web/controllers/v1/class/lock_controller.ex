defmodule ClassnavapiWeb.Api.V1.Class.LockController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.Lock
  alias Classnavapi.Class.Lock.Section
  alias Classnavapi.Repo

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@student_role, @syllabus_worker_role, @admin_role]}
  plug :verify_member, %{of: :school, using: :class_id}

  def lock(%{assigns: %{user: user}} = conn, %{"is_class" => true} = params) do
    params = params |> Map.put("user_id", user.id)

    status = Repo.all(Section)
    |> Enum.map(&lock_class(Map.put(params, "class_lock_section_id", &1.id)))
    |> Enum.find({:ok, nil}, &errors(&1))

    case status do
      {:ok, _lock} -> conn |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def lock(%{assigns: %{user: user}} = conn, params) do
    params = params 
            |> Map.put("user_id", user.id)

    case lock_class(params) do
      {:ok, _lock} -> conn |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def unlock(%{assigns: %{user: user}} = conn, %{"class_id" => class_id, "is_class" => true} = params) do
    status = from(l in Lock)
                |> where([l], l.class_id == ^class_id and l.user_id == ^user.id and l.is_completed == false)
                |> Repo.all()
                |> Enum.map(&unlock_class(&1, params))
                |> Enum.find({:ok, nil}, &errors(&1))

    case status do
      {:ok, _lock} -> conn |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def unlock(%{assigns: %{user: user}} = conn, %{"class_id" => class_id, "class_lock_section_id" => section_id} = params) do
    lock_old = Repo.get_by!(Lock, user_id: user.id, class_id: class_id, class_lock_section_id: section_id, is_completed: false)

    case unlock_class(lock_old, params) do
      {:ok, _lock} -> conn |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp lock_class(params) do
    changeset = Lock.changeset(%Lock{}, params) 
    Repo.insert(changeset)
  end

  defp unlock_class(lock_old, %{"is_completed" => true}) do
    changeset = Lock.changeset(lock_old, %{is_completed: true})
    Repo.update(changeset)
  end

  defp unlock_class(lock_old, %{}) do
    Repo.delete(lock_old)
  end

  defp errors(tuple) do
    case tuple do
      {:error, _val} -> true
      _ -> false
    end
  end
end