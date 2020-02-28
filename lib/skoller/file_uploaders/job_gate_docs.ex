defmodule Skoller.FileUploaders.JobG8Docs do
  @moduledoc false
  # Provides doc upload utilities.
  # Defines valid extensions, filename, and storage path.
  # For more information, See `Arc`
  # S3 buckets are defined in env vars.

  use Arc.Definition

  @versions [:original]
  @acl :public_read

  @doc false
  # Override the persisted filenames:
  def filename(_version, {_file, %{id: id}}) do
    id <> ".xml"
  end

  @doc false
  # Override the storage directory:
  def storage_dir(_version, _params) do
    "job_gate_files/"
  end

  @doc false
  #this passes the mime type to s3.
  def s3_object_headers(_version, {_file, _scope}) do
    [content_type: "text/xml"]
  end
end