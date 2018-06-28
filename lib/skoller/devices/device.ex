defmodule Skoller.Devices.Device do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Devices.Device

  schema "user_devices" do
    field :type, :string
    field :udid, :string
    field :user_id, :id

    timestamps()
  end

  @req_fields [:udid, :type, :user_id]
  @all_fields @req_fields

  @doc false
  def changeset(%Device{} = device, attrs) do
    device
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> validate_inclusion(:type, ["ios", "android"])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_device, name: :user_devices_user_id_udid_index)
  end
end
