defmodule Skoller.ClassDocs do
  @moduledoc """
  Context module for class docs.
  """
  
  alias Skoller.DocUpload
  alias Ecto.UUID
  alias Skoller.Repo
  alias Skoller.ClassDocs.Doc
  alias Skoller.MapErrors
  alias Skoller.Classes.ClassStatuses

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

  @doc """
  Gets a doc by id

  ## Returns
  `%Skoller.ClassDocs.Doc{}` or `Ecto.NoResultsError`
  """
  def get_doc_by_id!(doc_id) do
    Repo.get!(Doc, doc_id)
  end

  @doc """
  Deletes a doc

  ## Returns
  `{:ok, %Skoller.ClassDocs.Doc{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def delete(%Doc{} = doc) do
    Repo.delete(doc)
  end

  @doc """
  Inserts a doc

  ## Returns
  `{:ok, %Skoller.ClassDocs.Doc{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def insert(params) do
    Doc.changeset(%Doc{}, params)
    |> Repo.insert()
  end

  @doc """
  Inserts a doc into multiple classes.

  May cause class status updates.

  ## Returns
  `{:ok, Map}` or `{:error, _, _, _}` where `Map` contains
   * `{:doc, [Skoller.ClassDocs.Doc]}`
   * `{:status, [Skoller.ClassStatuses.Status]}`
  """
  def multi_insert_docs(classes, params) do
    Ecto.Multi.new
    |> Ecto.Multi.run(:doc, &insert_class_doc(classes, params, &1))
    |> Ecto.Multi.run(:status, &check_statuses(classes, &1.doc))
    |> Repo.transaction()
  end

  defp check_statuses(classes, docs) do
    status = classes |> Enum.map(&ClassStatuses.check_status(&1, %{doc: elem(docs |> Enum.find(fn(x) -> elem(x, 1).class_id == &1.id end), 1)}))
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  defp insert_class_doc(classes, params, _) do
    status = classes |> Enum.map(&insert_doc(&1, params))
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end

  defp insert_doc(class, params) do
    params 
    |> Map.put("class_id", class.id)
    |> insert()
  end
end