defmodule Skoller.Auth do
  @moduledoc "Auth Guardian"
  use Guardian, otp_app: :skoller

  alias Skoller.{
    Users,
    Users.User
  }

  def subject_for_token(%{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :not_found}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Users.get_user_by_id(id) do
      %User{} = user -> {:ok, user}
      nil -> {:error, :no_resource_found}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :not_found}
  end
end
