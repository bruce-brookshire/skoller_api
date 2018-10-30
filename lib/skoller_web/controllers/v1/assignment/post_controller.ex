defmodule SkollerWeb.Api.V1.Assignment.PostController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias SkollerWeb.Assignment.PostView
  alias Skoller.AssignmentPosts.Notifications
  alias SkollerWeb.Responses.MultiError
  alias Skoller.AssignmentPosts

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled, :assignment
  plug :verify_member, :class_assignment

  def create(conn, params) do
    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    case AssignmentPosts.create(params) do
      {:ok, %{post: post}} ->
        Task.start(Notifications, :send_assignment_post_notification, [post, conn.assigns[:user].student_id])
        render(conn, PostView, "show.json", %{post: post})
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def update(conn, %{"id" => id} = params) do
    post_old = AssignmentPosts.get_post_by_student_and_id!(conn.assigns[:user].student_id, id)

    case AssignmentPosts.update(post_old, params) do
      {:ok, post} ->
        render(conn, PostView, "show.json", %{post: post})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end