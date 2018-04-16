defmodule Skoller.Devices do

  alias Skoller.Repo
  alias Skoller.Devices.Device

  import Ecto.Query
  
  def get_devices_by_user_id(id) do
    from(dev in Device)
    |> where([dev, user], dev.user_id == ^id)
    |> Repo.all
  end

  def get_device_by_attributes!(udid, type, user_id) do
    Repo.get_by!(Device, udid: udid, type: type, user_id: user_id)
  end

  def create_device(params) do
    %Device{}
    |> Device.changeset(params)
    |> Repo.insert()
  end

  def delete_device!(%Device{} = device) do
    device |> Repo.delete!()
  end
end