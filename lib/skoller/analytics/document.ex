defmodule Skoller.Analytics.Documents.Document do
    @moduledoc false
    use Ecto.Schema
    import Ecto.Changeset
    alias Skoller.Analytics.Documents.Document
  
    schema "analytics_documents" do
      field :path, :string
      field :analytics_document_type_id, :integer
      timestamps()
    end
  
    @req_fields [:path, :analytics_document_type_id]
    @all_fields @req_fields
  
    @doc false
    def changeset(%Document{} = point_type, attrs) do
      point_type
      |> cast(attrs, @all_fields)
      |> validate_required(@req_fields)
    end
  end