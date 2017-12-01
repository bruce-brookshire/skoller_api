defmodule ClassnavapiWeb.Api.V1.DeviceController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.User.Device
  alias ClassnavapiWeb.User.DeviceView
  
  import ClassnavapiWeb.Helpers.AuthPlug

  plug :verify_user

  def register(conn, %{} = params) do
    changeset = Device.changeset(%Device{}, params)

    case Repo.insert(changeset) do
      {:ok, user_device} ->
        conn |> render(DeviceView, "device.json", device: user_device)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end