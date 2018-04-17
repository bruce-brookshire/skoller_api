defmodule SkollerWeb.Api.V1.Class.LockController do
  use SkollerWeb, :controller

  alias Skoller.Class.Lock
  alias Skoller.Class.AbandonedLock
  alias Skoller.Class.Lock.Section
  alias Skoller.Repo
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.Class.LockView
  alias Skoller.Classes
  alias Skoller.Users

  import Ecto.Query
  import SkollerWeb.Helpers.AuthPlug

  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@student_role, @syllabus_worker_role, @admin_role]}
  plug :verify_member, :class

  def index(conn, %{"class_id" => class_id}) do
    locks = Users.get_user_locks_by_class(class_id)

    render(conn, LockView, "index.json", locks: locks)
  end

  def lock(%{assigns: %{user: %{roles: roles}}} = conn, %{"is_class" => true} = params) do
    case Enum.any?(roles, & &1.id == @admin_role) do
      true -> lock_admin(conn, params)
      false -> lock_diy(conn, params)
    end
  end

  def lock(%{assigns: %{user: user}} = conn, params) do
    params = params 
            |> Map.put("user_id", user.id)

    case lock_class(params) do
      {:ok, _lock} -> conn |> send_resp(204, "")
      {:error, changeset} ->
        conn
        |> put_status(:conflict)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def unlock(%{assigns: %{user: user}} = conn, %{"is_class" => true} = params) do
    old_class = Classes.get_class_by_id(params["class_id"])

    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:unlock, &unlock_full_class(user, params, &1))
    |> Ecto.Multi.run(:status, &Classes.check_status(old_class, &1))

    case Repo.transaction(multi) do
      {:ok, %{status: class}} -> 
        Classes.evaluate_class_completion(old_class, class)
        conn |> send_resp(204, "")
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def unlock(%{assigns: %{user: user}} = conn, %{"class_id" => class_id, "class_lock_section_id" => section_id} = params) do
    lock_old = Repo.get_by!(Lock, user_id: user.id, class_id: class_id, class_lock_section_id: section_id, is_completed: false)

    old_class = Classes.get_class_by_id(params["class_id"])

    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:unlock, &unlock_lock(lock_old, params, &1))
    |> Ecto.Multi.run(:status, &Classes.check_status(old_class, &1))

    case Repo.transaction(multi) do
      {:ok, %{status: class}} -> 
        Classes.evaluate_class_completion(old_class, class)
        conn |> send_resp(204, "")
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp lock_admin(%{assigns: %{user: user}} = conn, params) do
    params = params |> Map.put("user_id", user.id)
    
    from(sect in Section)
    |> where([sect], sect.is_diy == true)
    |> Repo.all()
    |> Enum.each(&lock_class(Map.put(params, "class_lock_section_id", &1.id)))

    conn |> send_resp(204, "")
  end

  defp lock_diy(%{assigns: %{user: user}} = conn, %{"class_id" => class_id} = params) do
    params = params |> Map.put("user_id", user.id)
    
    class = Classes.get_class_by_id!(class_id)
            |> Repo.preload(:school)

    case class.school.is_diy_enabled do
      true -> conn |> lock_full_class(params)
      false -> conn |> send_resp(401, "")
    end
  end

  defp lock_full_class(conn, params) do
    sections = from(sect in Section)
    |> where([sect], sect.is_diy == true)
    |> Repo.all()

    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:sections, &lock_sections(sections, params, &1))

    case Repo.transaction(multi) do
      {:ok, _lock} -> conn |> send_resp(204, "")
      {:error, _error} ->
        conn
        |> send_resp(409, "")
    end
  end

  defp lock_sections(sections, params, _) do
    sections
    |> Enum.map(&lock_class(Map.put(params, "class_lock_section_id", &1.id)))
    |> Enum.find({:ok, nil}, &RepoHelper.errors(&1))
  end

  defp unlock_full_class(user, %{"class_id" => class_id} = params, _) do
    status = from(l in Lock)
    |> where([l], l.class_id == ^class_id and l.user_id == ^user.id and l.is_completed == false)
    |> Repo.all()
    |> Enum.map(&unlock_lock(&1, params))

    status
    |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end

  defp lock_class(params) do
    case Repo.get_by(Lock, class_id: params["class_id"], 
                            class_lock_section_id: params["class_lock_section_id"], 
                            user_id: params["user_id"],
                            is_completed: false) do
      nil ->           
        changeset = Lock.changeset(%Lock{}, params) 
        Repo.insert(changeset)
      lock -> {:ok, lock} 
    end
  end

  defp unlock_lock(lock_old, map, _) do
    unlock_lock(lock_old, map)
  end

  defp unlock_lock(lock_old, %{"is_completed" => true}) do
    changeset = Lock.changeset(lock_old, %{is_completed: true})
    Repo.update(changeset)
  end

  defp unlock_lock(lock_old, %{}) do
    Repo.insert!(%AbandonedLock{
      class_lock_section_id: lock_old.class_lock_section_id,
      class_id: lock_old.class_id,
      user_id: lock_old.user_id
    })
    Repo.delete(lock_old)
  end
end