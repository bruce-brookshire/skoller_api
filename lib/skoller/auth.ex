defmodule Skoller.Auth do

  @moduledoc """
  
  Guardian Token Auth module.

  subject_for_token/2 is used during encode_and_sign/2

  resource_from_claims/1 is used during Guardian.Plug.LoadResource

  """

  use Guardian, otp_app: :skoller

  def subject_for_token(resource, _claims) do
    {:ok, to_string(resource.id)}
  end

  def resource_from_claims(%{"sub" => sub}) do
    {:ok, sub}
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end
end
