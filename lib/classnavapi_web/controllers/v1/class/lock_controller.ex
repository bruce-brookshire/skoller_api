defmodule ClassnavapiWeb.Api.V1.Class.LockController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.Lock
  alias Classnavapi.Class.AbandonedLock
  alias Classnavapi.Class.Lock.Section
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Helpers.StatusHelper
  alias Classnavapi.Class
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias ClassnavapiWeb.Helpers.NotificationHelper

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300

  @complete_status 700
  
  plug :verify_role, %{roles: [@student_role, @syllabus_worker_role, @admin_role]}
  plug :verify_member, %{of: :school, using: :class_id}

  def lock(%{assigns: %{user: user}} = conn, %{"is_class" => true} = params) do
    params = params |> Map.put("user_id", user.id)

    status = from(sect in Section)
    |> where([sect], sect.is_diy == true)
    |> Repo.all()
    |> Enum.map(&lock_class(Map.put(params, "class_lock_section_id", &1.id)))
    |> Enum.find({:ok, nil}, &RepoHelper.errors(&1))

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

  def unlock(%{assigns: %{user: user}} = conn, %{"is_class" => true} = params) do

    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:unlock, &unlock_full_class(user, params, &1))
    |> Ecto.Multi.run(:status, &process_unlocks(&1, params))

    case Repo.transaction(multi) do
      {:ok, %{status: %Class{class_status_id: @complete_status} = class}} -> 
        Task.start(NotificationHelper, :send_class_complete_notification, [class])
        conn |> send_resp(204, "")
      {:ok, _lock} -> 
        conn |> send_resp(204, "")
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def unlock(%{assigns: %{user: user}} = conn, %{"class_id" => class_id, "class_lock_section_id" => section_id} = params) do
    lock_old = Repo.get_by!(Lock, user_id: user.id, class_id: class_id, class_lock_section_id: section_id, is_completed: false)

    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:unlock, &unlock_class(lock_old, params, &1))
    |> Ecto.Multi.run(:status, &process_unlocks(&1, params))

    case Repo.transaction(multi) do
      {:ok, %{status: %Class{class_status_id: @complete_status} = class}} -> 
        Task.start(NotificationHelper, :send_class_complete_notification, [class])
        conn |> send_resp(204, "")
      {:ok, _lock} -> 
        conn |> send_resp(204, "")
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp process_unlocks(%{unlock: []}, _map), do: {:ok, nil}
  defp process_unlocks(%{unlock: %Lock{} = unlock}, params) do
    check_class_status(unlock, params)
  end
  defp process_unlocks(%{unlock: unlock}, params) do
    status = unlock |> Enum.map(&check_class_status(&1, params))
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end

  defp check_class_status({:ok, lock}, params), do: check_class_status(lock, params)
  defp check_class_status(%Lock{is_completed: true} = lock, params) do
    Repo.get!(Class, lock.class_id)
    |> Ecto.Changeset.change()
    |> StatusHelper.unlock_class(params)
    |> Repo.update()
  end
  defp check_class_status(_tuple, _map), do: {:ok, nil}

  defp unlock_full_class(user, %{"class_id" => class_id} = params, _) do
    status = from(l in Lock)
    |> where([l], l.class_id == ^class_id and l.user_id == ^user.id and l.is_completed == false)
    |> Repo.all()
    |> Enum.map(&unlock_class(&1, params))

    status
    |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end

  defp lock_class(params) do
    changeset = Lock.changeset(%Lock{}, params) 
    Repo.insert(changeset)
  end

  defp unlock_class(lock_old, map, _) do
    unlock_class(lock_old, map)
  end

  defp unlock_class(lock_old, %{"is_completed" => true}) do
    changeset = Lock.changeset(lock_old, %{is_completed: true})
    Repo.update(changeset)
  end

  defp unlock_class(lock_old, %{}) do
    Repo.insert!(%AbandonedLock{
      class_lock_section_id: lock_old.class_lock_section_id,
      class_id: lock_old.class_id,
      user_id: lock_old.user_id
    })
    Repo.delete(lock_old)
  end
end