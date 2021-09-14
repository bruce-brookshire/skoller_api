defmodule Skoller.PaymentsTest do
  use Skoller.DataCase

  alias Skoller.Payments

  describe "customers_info" do
    alias Skoller.Payments.Stripe

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def stripe_fixture(attrs \\ %{}) do
      {:ok, stripe} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Payments.create_stripe()

      stripe
    end

    test "list_customers_info/0 returns all customers_info" do
      stripe = stripe_fixture()
      assert Payments.list_customers_info() == [stripe]
    end

    test "get_stripe!/1 returns the stripe with given id" do
      stripe = stripe_fixture()
      assert Payments.get_stripe!(stripe.id) == stripe
    end

    test "create_stripe/1 with valid data creates a stripe" do
      assert {:ok, %Stripe{} = stripe} = Payments.create_stripe(@valid_attrs)
    end

    test "create_stripe/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Payments.create_stripe(@invalid_attrs)
    end

    test "update_stripe/2 with valid data updates the stripe" do
      stripe = stripe_fixture()
      assert {:ok, %Stripe{} = stripe} = Payments.update_stripe(stripe, @update_attrs)
    end

    test "update_stripe/2 with invalid data returns error changeset" do
      stripe = stripe_fixture()
      assert {:error, %Ecto.Changeset{}} = Payments.update_stripe(stripe, @invalid_attrs)
      assert stripe == Payments.get_stripe!(stripe.id)
    end

    test "delete_stripe/1 deletes the stripe" do
      stripe = stripe_fixture()
      assert {:ok, %Stripe{}} = Payments.delete_stripe(stripe)
      assert_raise Ecto.NoResultsError, fn -> Payments.get_stripe!(stripe.id) end
    end

    test "change_stripe/1 returns a stripe changeset" do
      stripe = stripe_fixture()
      assert %Ecto.Changeset{} = Payments.change_stripe(stripe)
    end
  end
end
