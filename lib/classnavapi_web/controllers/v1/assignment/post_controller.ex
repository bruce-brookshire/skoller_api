defmodule ClassnavapiWeb.Api.V1.Assignment.PostController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Assignment.Post
  alias ClassnavapiWeb.Assignment.PostView
  alias ClassnavapiWeb.Helpers.NotificationHelper
  alias Classnavapi.Class.StudentAssignment
  alias Classnavapi.Class.StudentClass
  alias ClassnavapiWeb.Helpers.RepoHelper

  import ClassnavapiWeb.Helpers.AuthPlug
  import ClassnavapiWeb.Helpers.ChatPlug
  import Ecto.Query

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
        Task.start(NotificationHelper, :send_assignment_post_notification, [post, conn.assigns[:user].student_id])
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
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp un_read_assign(post) do
    status = from(sa in StudentAssignment)
    |> join(:inner, [sa], sc in StudentClass, sc.id == sa.student_class_id)
    |> where([sa], sa.assignment_id == ^post.assignment_id)
    |> where([sa, sc], sc.student_id != ^post.student_id)
    |> Repo.all()
    |> Enum.map(&Repo.update(Ecto.Changeset.change(&1, %{is_read: false})))

    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
end