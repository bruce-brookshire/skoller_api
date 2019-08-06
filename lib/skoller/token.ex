defmodule Skoller.Token do
    @moduledoc """
    Helper for token generation.
    """
  
    alias Skoller.Auth
  
    @doc """
    Gets a token for the user `id`. Should not be used unless the user should get a token.

    ## Returns
    `{:ok, token}`
    """
    def login(id) do
      {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"}, ttl: {1, :day})
      {:ok, token}
    end

    @doc """
    Gets a token for the user `id`. Should not be used unless the user should get a token.

    ## Returns
    `{:ok, token}`
    """
    def long_token(id) do
      {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"}, ttl: {180, :day})
      {:ok, token}
    end
  
    @doc """
    Gets a token for the user `id`. Should not be used unless the user should get a token.

    `token` lifespan is 1 hour.

    ## Returns
    `{:ok, token}`
    """
    def short_token(id) do
      {:ok, token, _} = Auth.encode_and_sign(%{:id => id}, %{typ: "access"}, ttl: {60, :minute})
      {:ok, token}
    end
  end