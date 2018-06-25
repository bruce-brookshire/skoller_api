defmodule SkollerWeb.Api.V1.DeviceController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Devices
  alias SkollerWeb.User.DeviceView
  
  import SkollerWeb.Helpers.AuthPlug

  plug :verify_user

  def register(conn, params) do
    case Devices.create_device(params) do
      {:ok, user_device} ->
        conn |> render(DeviceView, "device.json", device: user_device)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end