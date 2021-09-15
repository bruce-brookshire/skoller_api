defmodule SkollerWeb.StripeControllerTest do
  use SkollerWeb.ConnCase

  alias Skoller.Payments
  alias Skoller.Payments.Stripe

  @create_attrs %{

  }
  @update_attrs %{

  }
  @invalid_attrs %{}

  def fixture(:stripe) do
    {:ok, stripe} = Payments.create_stripe(@create_attrs)
    stripe
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all customers_info", %{conn: conn} do
      conn = get(conn, Routes.stripe_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create stripe" do
    test "renders stripe when data is valid", %{conn: conn} do
      conn = post(conn, Routes.stripe_path(conn, :create), stripe: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.stripe_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.stripe_path(conn, :create), stripe: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update stripe" do
    setup [:create_stripe]

    test "renders stripe when data is valid", %{conn: conn, stripe: %Stripe{id: id} = stripe} do
      conn = put(conn, Routes.stripe_path(conn, :update, stripe), stripe: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.stripe_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, stripe: stripe} do
      conn = put(conn, Routes.stripe_path(conn, :update, stripe), stripe: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete stripe" do
    setup [:create_stripe]

    test "deletes chosen stripe", %{conn: conn, stripe: stripe} do
      conn = delete(conn, Routes.stripe_path(conn, :delete, stripe))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.stripe_path(conn, :show, stripe))
      end
    end
  end

  defp create_stripe(_) do
    stripe = fixture(:stripe)
    %{stripe: stripe}
  end
end
