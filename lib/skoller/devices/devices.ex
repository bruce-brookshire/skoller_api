defmodule Skoller.Devices do

  alias Skoller.Repo
  alias Skoller.Users.Device

  import Ecto.Query
  
  def get_devices_by_user_id(id) do
    from(dev in Device)
    |> where([dev, user], dev.user_id == ^id)
    |> Repo.all
  end
end