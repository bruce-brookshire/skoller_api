defmodule Classnavapi.PicUpload do
  @moduledoc """
    Provides doc upload utilities.

    Defines valid extensions, filename, and storage path.
  """

  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original, :thumb]
  @extensions ~w(.jpg .png .jpeg .gif)
  @acl :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname |> String.downcase
    Enum.member?(@extensions, file_extension)
  end

  def transform(:thumb, _) do
    {:convert, "-thumbnail 100x100^ -gravity center -extent 100x100 -format png", :png}
  end

  # Override the persisted filenames:
  def filename(_version, {_file, scope}) do
    scope["id"]
  end

  # Override the storage directory:
  def storage_dir(_, _) do
    "uploads/thumbs/"
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
