defmodule Classnavapi.ProfessorTest do
  use Classnavapi.DataCase

  alias Classnavapi.Professor

  @valid_attrs %{email: "prof@email.edu",
                name_first: "Professor", 
                name_last: "Taco", 
                office_availability: "Never", 
                office_location: "Earth",
                phone: "6158675309",
                class_period_id: 1}

  test "professor insert with valid attributes" do
    changeset = Professor.changeset_insert(%Professor{}, @valid_attrs)
    assert changeset.valid?
  end

  test "professor insert email optional" do
    changeset = Professor.changeset_insert(%Professor{}, Map.delete(@valid_attrs, :email))
    assert changeset.valid?
  end

  test "professor insert first name optional" do
    changeset = Professor.changeset_insert(%Professor{}, Map.delete(@valid_attrs, :name_first))
    assert changeset.valid?
  end

  test "professor insert office availability optional" do
    changeset = Professor.changeset_insert(%Professor{}, Map.delete(@valid_attrs, :office_availability))
    assert changeset.valid?
  end

  test "professor insert office location optional" do
    changeset = Professor.changeset_insert(%Professor{}, Map.delete(@valid_attrs, :office_location))
    assert changeset.valid?
  end

  test "professor insert phone optional" do
    changeset = Professor.changeset_insert(%Professor{}, Map.delete(@valid_attrs, :phone))
    assert changeset.valid?
  end

  test "professor insert email bad format" do
    changeset = Professor.changeset_insert(%Professor{}, %{@valid_attrs | email: "noatsymbol"})
    refute changeset.valid?
  end

  test "professor insert no last name" do
    changeset = Professor.changeset_insert(%Professor{}, Map.delete(@valid_attrs, :name_last))
    refute changeset.valid?
  end

  test "professor insert no class period" do
    changeset = Professor.changeset_insert(%Professor{}, Map.delete(@valid_attrs, :class_period_id))
    refute changeset.valid?
  end
end