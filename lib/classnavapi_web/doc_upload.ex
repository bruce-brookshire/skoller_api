defmodule Classnavapi.DocUpload do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original]
  @extensions ~w(.pdf .doc .docx)

  # Whitelist file extensions:
  def validate({file, _}) do
    @extensions |> Enum.member?(Path.extname(file.file_name))
  end

  # Override the persisted filenames:
  # def filename(version, _) do
  #   version
  # end

  # Override the storage directory:
  def storage_dir(version, {file, scope}) do
    "uploads/class/docs/#{scope.id}"
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
