defmodule Skoller.CSVUpload do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.CSVUpload

  schema "csv_uploads" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%CSVUpload{} = csv_upload, attrs) do
    csv_upload
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:upload, name: :csv_unique_index)
  end
end
