defmodule SkollerWeb.Api.V1.Assignment.PostController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Assignment.PostView
  alias Skoller.AssignmentPosts

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled, :assignment
  plug :verify_member, :class_assignment

  def create(conn, params) do
    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    case AssignmentPosts.create_assignment_post(params) do
      {:ok, post} ->
        conn
        |> put_view(PostView)
        |> render("show.json", %{post: post})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    post_old = AssignmentPosts.get_post_by_student_and_id!(conn.assigns[:user].student_id, id)

    case AssignmentPosts.update_assignment_post(post_old, params) do
      {:ok, post} ->
        conn
        |> put_view(PostView)
        |> render("show.json", %{post: post})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
