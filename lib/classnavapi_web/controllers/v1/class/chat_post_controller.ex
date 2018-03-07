defmodule ClassnavapiWeb.Api.V1.Class.ChatPostController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Chat.Post
  alias ClassnavapiWeb.Class.ChatPostView
  alias Classnavapi.Chat.Post.Star
  alias Classnavapi.Class.StudentClass

  import ClassnavapiWeb.Helpers.AuthPlug
  import ClassnavapiWeb.Helpers.ChatPlug

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, %{"class_id" => class_id} = params) do

    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    changeset = Post.changeset(%Post{}, params)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:post, changeset)
    |> Ecto.Multi.run(:star, &insert_star(&1.post, conn.assigns[:user].student_id))

    case Repo.transaction(multi) do
      {:ok, %{post: post}} -> 
        sc = Repo.get_by!(StudentClass, student_id: conn.assigns[:user].student_id, class_id: class_id, is_dropped: false)
        render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: post, color: sc.color}, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "class_id" => class_id} = params) do

    post_old = Repo.get_by!(Post, id: id, student_id: conn.assigns[:user].student_id)

    changeset = Post.changeset_update(post_old, params)

    case Repo.update(changeset) do
      {:ok, post} -> 
        sc = Repo.get_by!(StudentClass, student_id: conn.assigns[:user].student_id, class_id: class_id, is_dropped: false)
        render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: post, color: sc.color}, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp insert_star(post, student_id) do
    %Star{}
    |> Star.changeset(%{chat_post_id: post.id, student_id: student_id})
    |> Repo.insert()
  end
end