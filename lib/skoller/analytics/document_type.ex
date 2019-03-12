defmodule Skoller.Analytics.Documents.DocumentType do
    @moduledoc false
    use Ecto.Schema
    import Ecto.Changeset
    alias Skoller.Analytics.Documents.DocumentType
  
    schema "analytics_document_types" do
      field :name, :string
      timestamps()
    end
  
    @req_fields [:name]
    @all_fields @req_fields
  
    @doc false
    def changeset(%DocumentType{} = point_type, attrs) do
      point_type
      |> cast(attrs, @all_fields)
      |> validate_required(@req_fields)
    end
  end