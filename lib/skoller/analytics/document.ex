defmodule Skoller.Analytics.Documents.Document do
    @moduledoc false
    use Ecto.Schema
    import Ecto.Changeset
    alias Skoller.Analytics.Documents.Document

    schema "analytics_documents" do
      field :path, :string
      field :analytics_document_type_id, :integer
      field :status, :string
      timestamps()
    end

    @req_fields [:analytics_document_type_id]
    @opt_fields [:path, :status]
    @all_fields @req_fields ++ @opt_fields

    @doc false
    def changeset(%Document{} = point_type, attrs) do
      point_type
      |> cast(attrs, @all_fields)
      |> validate_required(@req_fields)
    end
  end
