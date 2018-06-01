defmodule Skoller.Users.Report do
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Users.Report


  schema "user_reports" do
    field :context, :string
    field :note, :string
    field :user_id, :id

    timestamps()
  end

  @req_fields [:user_id, :context]
  @opt_fields [:note]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%Report{} = report, attrs) do
    report
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
