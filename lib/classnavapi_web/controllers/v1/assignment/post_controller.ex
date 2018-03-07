defmodule ClassnavapiWeb.Api.V1.Assignment.PostController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Assignment.Post
  alias ClassnavapiWeb.Assignment.PostView

  import ClassnavapiWeb.Helpers.AuthPlug

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :verify_member, :class_assignment

  def create(conn, params) do
    params = params |> Map.put("student_id", conn.assigns[:user].student_id)
    
    changeset = Post.changeset(%Post{}, params)

    case Repo.insert(changeset) do
      {:ok, post} -> 
        render(conn, PostView, "show.json", %{post: post})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end