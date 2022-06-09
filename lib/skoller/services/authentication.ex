defmodule Skoller.Services.Authentication do
  @moduledoc """
  A context module for authentication to abstract third party libraries out of
  the business logic.
  """

  @doc """
  Checks a password by comparing the `password` and the `hash`.

  Returns a boolean.
  """
  def check_password(password, hash) do
    Bcrypt.verify_pass(password, hash)
  end

  @doc """
  Hashes a `password`.

  Returns a hash.
  """
  def hash_password(password) do
    Bcrypt.add_hash(password)
  end
end
