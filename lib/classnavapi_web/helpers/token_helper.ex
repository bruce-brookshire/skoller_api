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
end