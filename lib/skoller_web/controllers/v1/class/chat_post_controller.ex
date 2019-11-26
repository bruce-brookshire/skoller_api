defmodule SkollerWeb.Api.V1.Class.ChatPostController do
  @moduledoc false

  use SkollerWeb, :controller

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

    case ChatPosts.create_post(params, conn.assigns[:user].student_id) do
      {:ok, post} ->
        sc = EnrolledStudents.get_enrolled_class_by_ids!(class_id, conn.assigns[:user].student_id)

        conn
        |> put_view(ChatPostView)
        |> render("show.json", %{
          chat_post: %{chat_post: post, color: sc.color},
          current_student_id: conn.assigns[:user].student_id
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "class_id" => class_id} = params) do
    post_old = ChatPosts.get_post_by_student_and_id!(conn.assigns[:user].student_id, id)

    case ChatPosts.update(post_old, params) do
      {:ok, post} ->
        sc = EnrolledStudents.get_enrolled_class_by_ids!(class_id, conn.assigns[:user].student_id)

        conn
        |> put_view(ChatPostView)
        |> render("show.json", %{
          chat_post: %{chat_post: post, color: sc.color},
          current_student_id: conn.assigns[:user].student_id
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
