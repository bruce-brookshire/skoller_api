defmodule SkollerWeb.Api.V1.UserController do
  use SkollerWeb, :controller

  alias Skoller.Users
  alias SkollerWeb.UserView
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.PicUpload
  alias Ecto.UUID

  import SkollerWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  
  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_user, :allow_admin

  def update(conn, %{"user_id" => id} = params) do
    user_old = Users.get_user_by_id!(id)

    location = params |> upload_pic()
    params = params |> Map.put("pic_path", location)

    case Users.update_user(user_old, params) do
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
end
