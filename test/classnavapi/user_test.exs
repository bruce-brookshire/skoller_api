defmodule Classnavapi.UserTest do
  use Classnavapi.DataCase

  alias Classnavapi.User

  @valid_attrs %{email: "test@classnav.com", password: "test"}
  @no_attrs %{email: "", password: "test"}
  @invalid_attrs %{email: "noatsign", password: "test"}
  @no_pass %{email: "test@classnav.com", password: ""}

  test "changeset with valid attributes" do
    changeset = User.changeset_insert(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with no email" do
    changeset = User.changeset_insert(%User{}, @no_attrs)
    refute changeset.valid?
  end

  test "changeset with invalid email" do
    changeset = User.changeset_insert(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset with no password" do
    changeset = User.changeset_insert(%User{}, @no_pass)
    refute changeset.valid?
  end
end