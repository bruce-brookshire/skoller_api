defmodule Skoller.CSVUploads do
  @moduledoc """
  A Context module for CSV uploads
  """

  alias Skoller.Repo
  alias Skoller.CSVUploads.CSVUpload

  @doc """
  Inserts a csv upload.

  ## Returns
  `{:ok, upload}` or `{:error, changeset}`
  """
  def create_csv_upload(filename) do
    CSVUpload.changeset(%CSVUpload{}, %{name: filename})
    |> Repo.insert()
  end
end