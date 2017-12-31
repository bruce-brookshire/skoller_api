defmodule Classnavapi.DocUpload do
  @moduledoc """
    Provides doc upload utilities.

    Defines valid extensions, filename, and storage path.
  """

  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original]
  @extensions ~w(.pdf .txt .rtf .jpg .png .jpeg .doc .docx .pages)
  @acl :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    @extensions |> Enum.member?(Path.extname(file.file_name))
  end

  # Override the persisted filenames:
  def filename(_version, {_file, scope}) do
    scope["id"]
  end

  # Override the storage directory:
  def storage_dir(_, _) do
    "uploads/class/docs/"
  end

  def s3_object_headers(_version, {file, _scope}) do
    [content_type: Plug.MIME.path(file.file_name)] # for "image.png", would produce: "image/png"
  end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: Plug.MIME.path(file.file_name)]
  # end
end
