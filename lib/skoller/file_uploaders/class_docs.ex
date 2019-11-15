defmodule Skoller.FileUploaders.ClassDocs do
  @moduledoc false
  # Provides doc upload utilities.
  # Defines valid extensions, filename, and storage path.
  # For more information, See `Arc`
  # S3 buckets are defined in env vars.

  use Arc.Definition

  @versions [:original]
  @extensions ~w(.pdf .txt .rtf .jpg .png .jpeg .doc .docx .pages)
  @acl :public_read

  @doc false
  # Whitelist file extensions:
  def validate({file, _}) do
    @extensions |> Enum.member?(Path.extname(file.file_name))
  end

  @doc false
  # Override the persisted filenames:
  def filename(_version, {_file, scope}) do
    scope["id"]
  end

  @doc false
  # Override the storage directory:
  def storage_dir(_, _) do
    "uploads/class/docs/"
  end

  @doc false
  # This is what runs the soffice_pdf bash script for when a file is not a pdf.
  def transform(:original, {file, _scope}) do
    case String.ends_with?(file.file_name, [".txt", ".rtf", ".doc", ".docx", ".pages", ".jpg", ".png", ".jpeg"]) do
      true -> {:soffice_pdf, fn(input, output) -> [input, output] end, :pdf}
      false -> :noaction
    end
  end

  @doc false
  #this passes the mime type to s3.
  def s3_object_headers(_version, {file, _scope}) do
    [content_type: MIME.from_path(file.file_name)] # for "image.png", would produce: "image/png"
  end
end
