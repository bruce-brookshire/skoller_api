defmodule SkollerWeb.Api.V1.Class.ChatPostController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.Chat.Post
  alias SkollerWeb.Class.ChatPostView
  alias Skoller.Chat.Post.Star
  alias Skoller.Students
  alias Skoller.ChatNotifications

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

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
        Task.start(ChatNotifications, :send_new_post_notification, [post, conn.assigns[:user].student_id])
        sc = Students.get_enrolled_class_by_ids!(class_id, conn.assigns[:user].student_id)
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
        sc = Students.get_enrolled_class_by_ids!(class_id, conn.assigns[:user].student_id)
        render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: post, color: sc.color}, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp insert_star(post, student_id) do
    %Star{}
    |> Star.changeset(%{chat_post_id: post.id, student_id: student_id})
    |> Repo.insert()
  end
end