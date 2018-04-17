defmodule SkollerWeb.Helpers.TokenHelper do

  @moduledoc """
  
  Helper for token generation.

  """

  alias Skoller.Auth

  def login(%{id: id}) do
    {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"}, ttl: {1, :day})
    {:ok, token}
  end

  def login(%{user: %{id: id}}) do
    {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"}, ttl: {1, :day})
    {:ok, token}
  end

  def short_token(%{id: id}) do
    {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"}, ttl: {60, :minute})
    {:ok, token}
  end

  def short_token(%{user: %{id: id}}) do
    {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"}, ttl: {60, :minute})
    {:ok, token}
  end
end