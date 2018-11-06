defmodule Skoller.ClassDocs do
  @moduledoc """
  Context module for class docs.
  """
  
  alias Skoller.DocUpload
  alias Ecto.UUID
  alias Skoller.Repo
  alias Skoller.ClassDocs.Doc
  alias Skoller.MapErrors
  alias Skoller.ClassStatuses.Classes, as: ClassStatuses
  alias Skoller.Sammi
  alias Skoller.Classes.Periods
  alias Skoller.Classes

  import Ecto.Query

  require Logger

  @doc """
  Gets a doc by id

  ## Returns
  `%Skoller.ClassDocs.Doc{}` or `Ecto.NoResultsError`
  """
  def get_doc_by_id!(doc_id) do
    Repo.get!(Doc, doc_id)
  end

  @doc """
  Gets all docs for a `class_id`

  ## Returns
  A list of `Doc`
  """
  def get_docs_by_class(class_id) do
    Repo.all(from docs in Doc, where: docs.class_id == ^class_id)
  end

  @doc """
  Deletes a doc

  ## Returns
  `{:ok, %Skoller.ClassDocs.Doc{}}` or `{:error, %Ecto.Changeset{}}`
  """
  def delete_doc(%Doc{} = doc) do
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
    Uploads a doc to a class. Runs sammi if `[sammi: true]` is passed as an option.

    Checks class status on insert.

    ## Behavior
    * `file` will be converted to a pdf
    * `file` will have it's name changed to an `Ecto.UUID`.

    ## Returns
    `{:ok, doc}` or `{:error, changeset}`
  """
  def upload_doc(file, user_id, class_id, is_syllabus, opts \\ []) do
    location = file |> upload_class_doc()

    if Keyword.get(opts, :sammi, false) do
      Task.start(Sammi, :sammi, [%{"is_syllabus" => is_syllabus, "class_id" => class_id}, location])
    end
  
    params = Map.new() 
    |> Map.put("path", location)
    |> Map.put("name", file.filename)
    |> Map.put("user_id", user_id)
    |> Map.put("is_syllabus", is_syllabus)
    |> Map.put("class_id", class_id)

    changeset = Doc.changeset(%Doc{}, params)

    class = Classes.get_class_by_id!(class_id)

    result = Ecto.Multi.new
    |> Ecto.Multi.insert(:doc, changeset)
    |> Ecto.Multi.run(:status, &ClassStatuses.check_status(class, &1))
    |> Repo.transaction()

    case result do
      {:ok, %{doc: doc}} ->
        {:ok, doc}
      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Inserts syllabi into multiple classes using a `class_hash` (class upload key) that is generated from the Scraper.

  May cause class status updates.

  Will run `Skoller.Sammi` on the file for each class.

  ## Returns
  `{:ok, Map}` or `{:error, _, _, _}` where `Map` contains
   * `{:doc, [Skoller.ClassDocs.Doc]}`
   * `{:status, [Skoller.ClassStatuses.Status]}`
  """
  def insert_multiple_syllabi_from_hash(class_hash, period_id, file, user_id) do
    classes = Periods.get_class_from_hash(class_hash, period_id)
    location = file |> upload_class_doc()

    classes |> Enum.each(&Task.start(Sammi, :sammi, [%{"is_syllabus" => "true", "class_id" => &1.id}, location]))

    params = Map.new() 
    |> Map.put("path", location)
    |> Map.put("name", file.filename)
    |> Map.put("is_syllabus", true)
    |> Map.put("user_id", user_id)

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

  # Uploads a class doc to S3.

  # ## Behavior
  #  * The document will be converted to a pdf
  #  * The document will have it's name changed to an `Ecto.UUID`.

  # ## Returns
  # The document location as a `String`
  
  defp upload_class_doc(file) do
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