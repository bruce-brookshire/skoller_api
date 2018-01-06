defmodule Classnavapi.UserRoleTest do
  use Classnavapi.DataCase

  alias Classnavapi.UserRole

  @valid_attrs %{user_id: 1, role_id: 100}

  test "changeset with valid attributes" do
    changeset = UserRole.changeset(%UserRole{}, @valid_attrs)
    assert changeset.valid?
  end

  test "user insert with no user_id" do
    changeset = UserRole.changeset(%UserRole{}, Map.delete(@valid_attrs, :user_id))
    refute changeset.valid?
  end

  test "user insert with no role_id" do
    changeset = UserRole.changeset(%UserRole{}, Map.delete(@valid_attrs, :role_id))
    refute changeset.valid?
  end
end