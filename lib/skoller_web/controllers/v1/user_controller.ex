defmodule SkollerWeb.Api.V1.UserController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.Users
  alias SkollerWeb.UserView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.FileUploaders.ProfilePics
  alias Skoller.Repo
  alias Ecto.UUID

  import SkollerWeb.Plugs.Auth

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_user, :allow_admin

  def update(conn, %{"user_id" => id} = params) do
    user_old = Users.get_user_by_id!(id)

    params =
      case params |> upload_pic() do
        nil ->
          params

        location ->
          params |> Map.put("pic_path", location)
      end

    is_admin = Enum.any?(conn.assigns.user.roles, &(&1.id == @admin_role))

    case Users.update_user(user_old, params, admin_update: is_admin) do
      {:ok, %{user: user}} ->
        user = user |> Repo.preload([:student, :roles], force: true)

        conn
        |> put_view(UserView)
        |> render("show.json", user: user)

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def delete(conn, %{"user_id" => id}) do
    case Users.delete_user(id) do
      {:ok, _} ->
        conn |> send_resp(204, "")

      {:error, 404} ->
        conn |> send_resp(404, "User not found")

      {:error, failed_value} ->
        conn |> MultiError.render(failed_value)
    end
  end

  defp upload_pic(%{"file" => ""}), do: ""

  defp upload_pic(%{"file" => file}) do
    scope = %{"id" => UUID.generate()}

    case ProfilePics.store({file, scope}) do
      {:ok, inserted} ->
        ProfilePics.url({inserted, scope}, :thumb)

      _ ->
        nil
    end
  end

  defp upload_pic(_params), do: nil
end
