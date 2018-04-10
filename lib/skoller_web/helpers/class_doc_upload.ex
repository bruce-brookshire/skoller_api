defmodule SkollerWeb.Helpers.ClassDocUpload do

  alias Skoller.DocUpload
  alias Ecto.UUID

  require Logger

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