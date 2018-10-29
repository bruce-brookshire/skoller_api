defmodule Skoller.SchoolsTest do
  use Skoller.DataCase

  alias Skoller.Schools

  describe "school_email_domains" do
    alias Skoller.Schools.EmailDomain

    @valid_attrs %{email_domain: "some email_domain"}
    @update_attrs %{email_domain: "some updated email_domain"}
    @invalid_attrs %{email_domain: nil}

    def email_domain_fixture(attrs \\ %{}) do
      {:ok, email_domain} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Schools.create_email_domain()

      email_domain
    end

    test "list_school_email_domains/0 returns all school_email_domains" do
      email_domain = email_domain_fixture()
      assert Schools.list_school_email_domains() == [email_domain]
    end

    test "get_email_domain!/1 returns the email_domain with given id" do
      email_domain = email_domain_fixture()
      assert Schools.get_email_domain!(email_domain.id) == email_domain
    end

    test "create_email_domain/1 with valid data creates a email_domain" do
      assert {:ok, %EmailDomain{} = email_domain} = Schools.create_email_domain(@valid_attrs)
      assert email_domain.email_domain == "some email_domain"
    end

    test "create_email_domain/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Schools.create_email_domain(@invalid_attrs)
    end

    test "update_email_domain/2 with valid data updates the email_domain" do
      email_domain = email_domain_fixture()
      assert {:ok, email_domain} = Schools.update_email_domain(email_domain, @update_attrs)
      assert %EmailDomain{} = email_domain
      assert email_domain.email_domain == "some updated email_domain"
    end

    test "update_email_domain/2 with invalid data returns error changeset" do
      email_domain = email_domain_fixture()
      assert {:error, %Ecto.Changeset{}} = Schools.update_email_domain(email_domain, @invalid_attrs)
      assert email_domain == Schools.get_email_domain!(email_domain.id)
    end

    test "delete_email_domain/1 deletes the email_domain" do
      email_domain = email_domain_fixture()
      assert {:ok, %EmailDomain{}} = Schools.delete_email_domain(email_domain)
      assert_raise Ecto.NoResultsError, fn -> Schools.get_email_domain!(email_domain.id) end
    end

    test "change_email_domain/1 returns a email_domain changeset" do
      email_domain = email_domain_fixture()
      assert %Ecto.Changeset{} = Schools.change_email_domain(email_domain)
    end
  end
end
