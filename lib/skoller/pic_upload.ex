defmodule Skoller.PicUpload do
  @moduledoc """
    Provides doc upload utilities.

    Defines valid extensions, filename, and storage path.

    For more information, See `Arc`

    S3 buckets are defined in env vars.
  """

  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:thumb] # to keep original images as well, add :original to this list.
  @extensions ~w(.jpg .png .jpeg .gif)
  @acl :public_read

  @doc false
  # Whitelist file extensions:
  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname |> String.downcase
    Enum.member?(@extensions, file_extension)
  end

  @doc false
  # this uses imagemagick to convert the :thumb version images to 200x200 thumbnails.
  def transform(:thumb, _) do
    {:convert, "-thumbnail 200x200^ -gravity center -extent 200x200 -format png", :png}
  end

  @doc false
  # Override the persisted filenames:
  def filename(_version, {_file, scope}) do
    scope["id"]
  end

  @doc false
  # Override the storage directory:
  def storage_dir(_, _) do
    "uploads/thumbs/"
  end
end
