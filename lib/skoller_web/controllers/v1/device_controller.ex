defmodule SkollerWeb.Api.V1.DeviceController do
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias Skoller.User.Device
  alias SkollerWeb.User.DeviceView
  
  import SkollerWeb.Helpers.AuthPlug

  plug :verify_user

  def register(conn, %{} = params) do
    changeset = Device.changeset(%Device{}, params)

    case Repo.insert(changeset) do
      {:ok, user_device} ->
        conn |> render(DeviceView, "device.json", device: user_device)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end