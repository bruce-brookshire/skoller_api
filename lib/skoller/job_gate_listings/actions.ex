defmodule Skoller.JobGateListings.Action do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.Users.User
  alias Skoller.JobGateListings.Listing
  alias Skoller.JobGateListings.Action

  schema "job_listing_user_actions" do
    field :user_id, :integer
    field :action, :string
    field :job_listing_sender_reference, :string

    belongs_to :user, User, define_field: false

    belongs_to :job_gate_listing, Listing,
      define_field: false,
      foreign_key: :job_listing_sender_reference,
      references: :sender_reference

    timestamps()
  end

  @req_fields [:user_id, :action, :job_listing_sender_reference]
  @all_fields @req_fields

  def insert_changeset(params) do
    %Action{}
    |> cast(params, @all_fields)
    |> validate_required(@req_fields)
  end
end

defmodule Skoller.JobGateListings.Actions do
  alias Skoller.Repo
  alias Skoller.JobGateListings.Action

  def create(%{} = action) do
    action
    |> Action.insert_changeset()
    |> Repo.insert()
  end
end
