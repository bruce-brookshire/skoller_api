defmodule Classnavapi.UserTest do
  use Classnavapi.DataCase

  alias Classnavapi.User

  @valid_attrs %{email: "test@classnav.com", password: "test"}

  test "user insert with valid attributes" do
    changeset = User.changeset_insert(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "user insert with no email" do
    changeset = User.changeset_insert(%User{}, Map.delete(@valid_attrs, :email))
    refute changeset.valid?
  end

  test "user insert with invalid email" do
    attrs = %{@valid_attrs | email: "noatsign"}
    changeset = User.changeset_insert(%User{}, attrs)
    refute changeset.valid?
  end

  test "user insert with no password" do
    changeset = User.changeset_insert(%User{}, Map.delete(@valid_attrs, :password))
    refute changeset.valid?
  end
end