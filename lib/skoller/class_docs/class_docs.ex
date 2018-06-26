defmodule Skoller.ClassDocs do
  @moduledoc """
  Context module for class docs.
  """
  
  alias Skoller.DocUpload
  alias Ecto.UUID

  require Logger

  @doc """
  Uploads a class doc to S3.

  ## Behavior
   * The document will be converted to a pdf
   * The document will have it's name changed to an `Ecto.UUID`.

  ## Returns
  The document location as a `String`
  """
  def upload_class_doc(file) do
    scope = %{"id" => UUID.generate()}
    case DocUpload.store({file, scope}) do
      {:ok, inserted} ->
        DocUpload.url({inserted, scope})
      {:error, error} ->
        Logger.info(inspect(error))
        nil
    end
  end
end