defmodule Skoller.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false
  alias Skoller.Repo

  alias Skoller.Payments.Stripe

  @doc """
  Returns the list of customers_info.

  ## Examples

      iex> list_customers_info()
      [%Stripe{}, ...]

  """
  def list_customers_info do
    Repo.all(Stripe)
  end

  @doc """
  Gets a single stripe.

  Raises `Ecto.NoResultsError` if the Stripe does not exist.

  ## Examples

      iex> get_stripe!(123)
      %Stripe{}

      iex> get_stripe!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stripe!(id), do: Repo.get!(Stripe, id)

  def get_stripe_by_user_id(user_id), do: Repo.get_by(Stripe, %{user_id: user_id})

  @doc """
  Creates a stripe.

  ## Examples

      iex> create_stripe(%{field: value})
      {:ok, %Stripe{}}

      iex> create_stripe(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stripe(attrs \\ %{}) do
    %Stripe{}
    |> Stripe.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a stripe.

  ## Examples

      iex> update_stripe(stripe, %{field: new_value})
      {:ok, %Stripe{}}

      iex> update_stripe(stripe, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stripe(%Stripe{} = stripe, attrs) do
    stripe
    |> Stripe.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stripe.

  ## Examples

      iex> delete_stripe(stripe)
      {:ok, %Stripe{}}

      iex> delete_stripe(stripe)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stripe(%Stripe{} = stripe) do
    Repo.delete(stripe)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stripe changes.

  ## Examples

      iex> change_stripe(stripe)
      %Ecto.Changeset{data: %Stripe{}}

  """
  def change_stripe(%Stripe{} = stripe, attrs \\ %{}) do
    Stripe.changeset(stripe, attrs)
  end
end
