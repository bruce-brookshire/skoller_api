defmodule ClassnavapiWeb.Helpers.TokenHelper do

  @moduledoc """
  
  Helper for token generation.

  """

  alias Classnavapi.Auth
  alias Classnavapi.User

  def login(%User{id: id}) do
    {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"})
    {:ok, token}
  end

  def login(%{user: %User{id: id}}) do
    {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"})
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