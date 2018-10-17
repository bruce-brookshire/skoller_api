defmodule SkollerWeb.Api.V1.Admin.Class.ChatPostController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias SkollerWeb.Class.ChatPostView
  alias Skoller.ChatPosts
  alias SkollerWeb.ChangesetView
  alias Skoller.EnrolledStudents

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :check_chat_enabled
  plug :verify_member, :class

  def delete(conn, %{"id" => id}) do
    post = conn |> get_post(id)
    case ChatPosts.delete(post) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"class_id" => class_id}) do
    posts = ChatPosts.get_posts_by_class(class_id)
    conn |> render_index_view(posts, class_id)
  end

  def show(conn, %{"id" => id}) do
    post = ChatPosts.get!(id)
    conn |> render_show_view(post)
  end

  # If a student is attempting to delete, verify it is their post.
  defp get_post(%{assigns: %{user: %{student: %{id: student_id}}}}, id) do
    ChatPosts.get_post_by_student_and_id!(student_id, id)
  end
  defp get_post(_conn, id) do
    ChatPosts.get!(id)
  end

  defp render_index_view(%{assigns: %{user: %{student: %{id: id}}}} = conn, posts, class_id) do
    sc = EnrolledStudents.get_enrolled_class_by_ids!(class_id, id)
    render(conn, ChatPostView, "index.json", %{chat_posts: %{chat_posts: posts, color: sc.color}, current_student_id: id})
  end
  defp render_index_view(conn, posts, _class_id) do
    render(conn, ChatPostView, "index.json", chat_posts: posts)
  end
  defp render_show_view(%{assigns: %{user: %{student: %{id: id}}}} = conn, post) do
    sc = EnrolledStudents.get_enrolled_class_by_ids!(post.class_id, id)
    render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: post, color: sc.color}, current_student_id: id})
  end
  defp render_show_view(conn, post) do
    render(conn, ChatPostView, "show.json", chat_post: post)
  end
end