defmodule Skoller.Devices do
  @moduledoc """
  Context module for devices.
  """

  alias Skoller.Repo
  alias Skoller.Devices.Device

  import Ecto.Query
  
  @doc """
  Gets all devices for a given user.

  ## Returns
  `[Skoller.Devices.Device]`
  """
  def get_devices_by_user_id(user_id) do
    from(dev in Device)
    |> where([dev, user], dev.user_id == ^user_id)
    |> Repo.all
  end

  @doc """
  Gets a device by udid, type, and user.

  ## Returns
  `Skoller.Devices.Device` or `Ecto.NoResultsError`
  """
  def get_device_by_attributes!(udid, type, user_id) do
    Repo.get_by!(Device, udid: udid, type: type, user_id: user_id)
  end

  @doc """
  Creates a device

  ## Returns
  `{:ok, Skoller.Devices.Device}` or `{:error, Ecto.Changeset}`
  """
  def create_device(params) do
    %Device{}
    |> Device.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Deletes a device

  ## Returns
  `Skoller.Devices.Device` or raises.
  """
  def delete_device!(%Device{} = device) do
    device |> Repo.delete!()
  end
end