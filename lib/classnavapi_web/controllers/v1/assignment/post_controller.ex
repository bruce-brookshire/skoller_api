defmodule ClassnavapiWeb.Api.V1.Assignment.PostController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Assignment.Post
  alias ClassnavapiWeb.Assignment.PostView
  alias ClassnavapiWeb.Helpers.NotificationHelper

  import ClassnavapiWeb.Helpers.AuthPlug
  import ClassnavapiWeb.Helpers.ChatPlug

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled, :assignment
  plug :verify_member, :class_assignment

  def create(conn, params) do
    params = params |> Map.put("student_id", conn.assigns[:user].student_id)
    
    changeset = Post.changeset(%Post{}, params)

    case Repo.insert(changeset) do
      {:ok, post} ->
        Task.start(NotificationHelper, :send_assignment_post_notification, [post, conn.assigns[:user].student_id])
        render(conn, PostView, "show.json", %{post: post})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    post_old = Repo.get!(Post, id)

    if post_old.student_id != conn.assigns[:user].student_id do
      conn |> send_resp(403, "") |> halt()
    end

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
end