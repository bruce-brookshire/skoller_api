defmodule ClassnavapiWeb.User.DeviceView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.User.DeviceView

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
