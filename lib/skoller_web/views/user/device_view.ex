defmodule SkollerWeb.User.DeviceView do
  use SkollerWeb, :view

  alias SkollerWeb.User.DeviceView

  def render("index.json", %{devices: devices}) do
    render_many(devices, DeviceView, "device.json")
  end

  def render("show.json", %{device: device}) do
    render_one(device, DeviceView, "device.json")
  end

  def render("device.json", %{device: device}) do
    %{
      id: device.id,
      udid: device.udid,
      device_type: device.type
    }
  end
end
