defmodule Classnavapi.School.EmailDomainTest do
  use Classnavapi.DataCase

  alias Classnavapi.School.EmailDomain

  @valid_attrs %{email_domain: "@classnav.com", is_professor_only: true}

  test "email domain with valid attributes" do
    changeset = EmailDomain.changeset(%EmailDomain{}, @valid_attrs)
    assert changeset.valid?
  end

  test "email domain with no email" do
    changeset = EmailDomain.changeset(%EmailDomain{}, Map.delete(@valid_attrs, :email_domain))
    refute changeset.valid?
  end

  test "email domain with invalid email" do
    changeset = EmailDomain.changeset(%EmailDomain{}, %{@valid_attrs | email_domain: "classnav"})
    refute changeset.valid?
  end

  test "email domain with no professor flag" do
    changeset = EmailDomain.changeset(%EmailDomain{}, Map.delete(@valid_attrs, :is_professor_only))
    refute changeset.valid?
  end
end