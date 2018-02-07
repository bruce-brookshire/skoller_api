defmodule ClassnavapiWeb.Api.V1.Admin.Class.ChatPostController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Chat.Post
  alias ClassnavapiWeb.Class.ChatPostView
  alias Classnavapi.Class.StudentClass

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query
  import ClassnavapiWeb.Helpers.ChatPlug

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :check_chat_enabled
  plug :verify_member, :class

  def delete(conn, %{"id" => id}) do
    post = Repo.get!(Post, id)
    case Repo.delete(post) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"class_id" => class_id}) do
    posts = from(p in Post)
    |> where([p], p.class_id == ^class_id)
    |> Repo.all()

    conn |> render_index_view(posts, class_id)
  end

  def show(conn, %{"id" => id}) do
    post = Repo.get!(Post, id)
    conn |> render_show_view(post)
  end

  defp render_index_view(%{assigns: %{user: %{student: %{id: id}}}} = conn, posts, class_id) do
    sc = Repo.get_by!(StudentClass, student_id: id, class_id: class_id, is_dropped: false)
    render(conn, ChatPostView, "index.json", %{chat_posts: %{chat_posts: posts, color: sc.color}, current_student_id: id})
  end
  defp render_index_view(conn, posts, _class_id) do
    render(conn, ChatPostView, "index.json", chat_posts: posts)
  end
  defp render_show_view(%{assigns: %{user: %{student: %{id: id}}}} = conn, post) do
    sc = Repo.get_by!(StudentClass, student_id: id, class_id: post.class_id, is_dropped: false)
    render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: post, color: sc.color}, current_student_id: id})
  end
  defp render_show_view(conn, post) do
    render(conn, ChatPostView, "show.json", chat_post: post)
  end
end