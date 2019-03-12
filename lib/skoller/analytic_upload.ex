defmodule Skoller.AnalyticUpload do
  @moduledoc false
  # Provides doc upload utilities.
  # Defines valid extensions, filename, and storage path.
  # For more information, See `Arc`
  # S3 buckets are defined in env vars.

  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original]
  @acl :public_read

  @doc false
  # Override the persisted filenames:
  def filename(_version, {_file, %{id: id}}) do
    id <> ".csv"
  end

  @doc false
  # Override the storage directory:
  def storage_dir(_version, {_file, %{dir: dir}}) do
    "analytics/#{dir}/"
  end

  @doc false
  #this passes the mime type to s3.
  def s3_object_headers(_version, {_file, _scope}) do
    [content_type: "text/csv"]
  end
end
