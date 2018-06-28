defmodule SkollerWeb.Api.V1.Assignment.PostController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.Assignment.Post
  alias SkollerWeb.Assignment.PostView
  alias Skoller.AssignmentPostNotifications
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.Students

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled, :assignment
  plug :verify_member, :class_assignment

  def create(conn, params) do
    params = params |> Map.put("student_id", conn.assigns[:user].student_id)
    
    changeset = Post.changeset(%Post{}, params)

    multi = Ecto.Multi.new()
    |> Ecto.Multi.insert(:post, changeset)
    |> Ecto.Multi.run(:student_assignment, &un_read_assign(&1.post))

    case Repo.transaction(multi) do
      {:ok, %{post: post}} ->
        Task.start(AssignmentPostNotifications, :send_assignment_post_notification, [post, conn.assigns[:user].student_id])
        render(conn, PostView, "show.json", %{post: post})
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def update(conn, %{"id" => id} = params) do
    post_old = Repo.get_by!(Post, id: id, student_id: conn.assigns[:user].student_id)

    changeset = Post.changeset_update(post_old, params)

    case Repo.update(changeset) do
      {:ok, post} ->
        render(conn, PostView, "show.json", %{post: post})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp un_read_assign(post) do
    status = Students.un_read_assignment(post.student_id, post.assignment_id)
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
end