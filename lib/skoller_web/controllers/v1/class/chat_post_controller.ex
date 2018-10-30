defmodule SkollerWeb.Api.V1.Class.ChatPostController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.ChatPosts.Post
  alias SkollerWeb.Class.ChatPostView
  alias Skoller.EnrolledStudents
  alias Skoller.ChatPosts

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, %{"class_id" => class_id} = params) do
    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    case ChatPosts.create(params, conn.assigns[:user].student_id) do
      {:ok, post} -> 
        sc = EnrolledStudents.get_enrolled_class_by_ids!(class_id, conn.assigns[:user].student_id)
        render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: post, color: sc.color}, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "class_id" => class_id} = params) do

    post_old = Repo.get_by!(Post, id: id, student_id: conn.assigns[:user].student_id)

    changeset = Post.changeset_update(post_old, params)

    case Repo.update(changeset) do
      {:ok, post} -> 
        sc = EnrolledStudents.get_enrolled_class_by_ids!(class_id, conn.assigns[:user].student_id)
        render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: post, color: sc.color}, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end