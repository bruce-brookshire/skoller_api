defmodule SkollerWeb.Helpers.TokenHelper do

  @moduledoc """
  
  Helper for token generation.

  """

  alias Skoller.Auth
  alias Skoller.Users.User

  def login(%User{id: id}) do
    {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"}, ttl: {1, :day})
    {:ok, token}
  end

  def login(%{user: %User{id: id}}) do
    {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"}, ttl: {1, :day})
    {:ok, token}
  end

  def short_token(%User{id: id}) do
    {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"}, ttl: {60, :minute})
    {:ok, token}
  end

  def short_token(%{user: %User{id: id}}) do
    {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"}, ttl: {60, :minute})
    {:ok, token}
  end
end