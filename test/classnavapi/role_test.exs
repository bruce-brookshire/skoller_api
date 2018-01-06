defmodule Classnavapi.RoleTest do
  use Classnavapi.DataCase

  alias Classnavapi.Role

  @valid_attrs %{id: 400, name: "Role"}

  test "role insert with valid attributes" do
    changeset = Role.changeset(%Role{}, @valid_attrs)
    assert changeset.valid?
  end

  test "role insert with no id" do
    changeset = Role.changeset(%Role{}, Map.delete(@valid_attrs, :id))
    refute changeset.valid?
  end

  test "role insert with no name" do
    changeset = Role.changeset(%Role{}, Map.delete(@valid_attrs, :name))
    refute changeset.valid?
  end
end