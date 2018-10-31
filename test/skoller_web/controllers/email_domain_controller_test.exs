defmodule SkollerWeb.EmailDomainControllerTest do
  use SkollerWeb.ConnCase

  alias Skoller.Schools
  alias Skoller.Schools.EmailDomain

  @create_attrs %{email_domain: "some email_domain"}
  @update_attrs %{email_domain: "some updated email_domain"}
  @invalid_attrs %{email_domain: nil}

  def fixture(:email_domain) do
    {:ok, email_domain} = Schools.create_email_domain(@create_attrs)
    email_domain
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all school_email_domains", %{conn: conn} do
      conn = get conn, email_domain_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create email_domain" do
    test "renders email_domain when data is valid", %{conn: conn} do
      conn = post conn, email_domain_path(conn, :create), email_domain: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, email_domain_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "email_domain" => "some email_domain"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, email_domain_path(conn, :create), email_domain: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update email_domain" do
    setup [:create_email_domain]

    test "renders email_domain when data is valid", %{conn: conn, email_domain: %EmailDomain{id: id} = email_domain} do
      conn = put conn, email_domain_path(conn, :update, email_domain), email_domain: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, email_domain_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "email_domain" => "some updated email_domain"}
    end

    test "renders errors when data is invalid", %{conn: conn, email_domain: email_domain} do
      conn = put conn, email_domain_path(conn, :update, email_domain), email_domain: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete email_domain" do
    setup [:create_email_domain]

    test "deletes chosen email_domain", %{conn: conn, email_domain: email_domain} do
      conn = delete conn, email_domain_path(conn, :delete, email_domain)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, email_domain_path(conn, :show, email_domain)
      end
    end
  end

  defp create_email_domain(_) do
    email_domain = fixture(:email_domain)
    {:ok, email_domain: email_domain}
  end
end
