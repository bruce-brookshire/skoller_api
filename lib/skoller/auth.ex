defmodule Skoller.Auth do
  @moduledoc """
  Auth module used by Guardian.
  """

  use Guardian, otp_app: :skoller

  # used during Skoller.Auth.encode_and_sign/2
  def subject_for_token(resource, _claims) do
    {:ok, to_string(resource.id)}
  end

  # used during Guardian.Plug.LoadResource
  def resource_from_claims(%{"sub" => sub}) do
    {:ok, sub}
  end
  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end
end
