defmodule SkollerWeb.Api.V1.DeviceController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Devices
  alias SkollerWeb.User.DeviceView
  
  import SkollerWeb.Plugs.Auth

  plug :verify_user

  def register(conn, params) do
    case Devices.get_device_by_attributes(params["udid"], params["type"], params["user_id"]) do
      nil ->
        conn |> create_device(params)
      device ->
        conn |> render(DeviceView, "device.json", device: device)
    end
  end

  defp create_device(conn, params) do
    case Devices.create_device(params) do
      {:ok, user_device} ->
        Task.start(Devices, :deregister_device_for_other_users_by_udid_and_type, [user_device])
        conn |> render(DeviceView, "device.json", device: user_device)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end 
end