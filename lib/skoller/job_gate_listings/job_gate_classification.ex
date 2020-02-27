defmodule Skoller.JobGateListings.JobGateClassification do
  use Ecto.Schema

  import Ecto.Query

  alias Skoller.Repo
  alias Skoller.JobGateListings.JobGateClassification

  schema "job_gate_classifications" do
    field :name, :string
  end

  def get_or_insert(classification) when is_binary(classification) do
    case Repo.get_by(JobGateClassification, name: classification) do
      nil ->
        Repo.insert!(%JobGateClassification{name: classification})

      result ->
        result
    end
  end
end

defmodule Skoller.JobGateListings.JobGateClassificationJoiner do
  use Ecto.Schema

  import Ecto.Changeset

  alias Skoller.JobGateListings.JobGateListing
  alias Skoller.JobGateListings.JobGateClassification
  alias Skoller.JobGateListings.JobGateClassificationJoiner

  schema "job_gate_classification_joiner" do
    field :job_gate_sender_reference, :string
    field :job_gate_classification_id, :integer
    field :is_primary, :boolean, default: false

    belongs_to :job_gate_classification, JobGateClassification, define_field: false

    belongs_to :job_gate_listing, JobGateListing,
      define_field: false,
      foreign_key: :job_gate_sender_reference,
      references: :sender_reference
  end

  @req_fields [:job_gate_listing_id, :job_gate_classification_id]
  @opt_fields [:is_primary]
  @all_fields @req_fields ++ @opt_fields

  def insert_changeset(params) do
    %JobGateClassificationJoiner{}
    |> cast(params, @all_fields)
    |> validate_required(@req_fields)
  end
end
