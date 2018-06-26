defmodule SkollerWeb.Api.V1.Admin.Class.ChatPostController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.Chat.Post
  alias SkollerWeb.Class.ChatPostView
  alias Skoller.Students

  import SkollerWeb.Plugs.Auth
  import Ecto.Query
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :check_chat_enabled
  plug :verify_member, :class

  def delete(%{assigns: %{user: %{student: %{id: student_id}}}} = conn, %{"id" => id}) do
    post = Repo.get_by!(Post, student_id: student_id, id: id)
    case Repo.delete(post) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Repo.get!(Post, id)
    case Repo.delete(post) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
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
    sc = Students.get_enrolled_class_by_ids!(class_id, id)
    render(conn, ChatPostView, "index.json", %{chat_posts: %{chat_posts: posts, color: sc.color}, current_student_id: id})
  end
  defp render_index_view(conn, posts, _class_id) do
    render(conn, ChatPostView, "index.json", chat_posts: posts)
  end
  defp render_show_view(%{assigns: %{user: %{student: %{id: id}}}} = conn, post) do
    sc = Students.get_enrolled_class_by_ids!(post.class_id, id)
    render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: post, color: sc.color}, current_student_id: id})
  end
  defp render_show_view(conn, post) do
    render(conn, ChatPostView, "show.json", chat_post: post)
  end
end