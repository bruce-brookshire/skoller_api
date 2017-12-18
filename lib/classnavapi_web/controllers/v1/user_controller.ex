defmodule ClassnavapiWeb.Api.V1.UserController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.User
  alias Classnavapi.Repo
  alias ClassnavapiWeb.UserView
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias Classnavapi.UserRole
  alias Classnavapi.PicUpload
  alias Ecto.UUID

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  
  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_user, :allow_admin

  def update(conn, %{"user_id" => id} = params) do
    user_old = Repo.get!(User, id)
    user_old = Repo.preload user_old, :student
    location = params |> upload_pic()

    params = params |> Map.put("pic_path", location)
    changeset = User.changeset_update(user_old, params)

    multi = Ecto.Multi.new
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.run(:roles, &check_student_role(changeset, &1))

    case Repo.transaction(multi) do
      {:ok, %{user: user}} ->
        render(conn, UserView, "show.json", user: user)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp upload_pic(%{"file" => file}) do
    scope = %{"id" => UUID.generate()} 
    case PicUpload.store({file, scope}) do
      {:ok, inserted} ->
        PicUpload.url({inserted, scope}, :thumb)
      _ ->
        nil
    end
  end
  defp upload_pic(_params), do: nil

  defp check_student_role(%Ecto.Changeset{changes: %{student: %Ecto.Changeset{action: :insert}}}, %{user: user}) do
    Repo.insert(%UserRole{user_id: user.id, role_id: @student_role})
  end
  defp check_student_role(_changeset, _user), do: {:ok, nil}
end
