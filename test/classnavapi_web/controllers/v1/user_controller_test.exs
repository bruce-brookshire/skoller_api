defmodule ClassnavapiWeb.Api.V1.UserControllerTest do
  use ClassnavapiWeb.ConnCase

  alias Classnavapi.Repo
  alias Classnavapi.User

  setup do
    {:ok, jwt, _} = Classnavapi.Auth.encode_and_sign(%{:id => 1}, %{typ: "access"})
    {:ok, %{jwt: jwt}}
  end

  test "index/2 responds with all Users", %{jwt: jwt} do
    users = [ User.changeset_insert(%User{}, %{email: "john@example.com", password: "test"}),
              User.changeset_insert(%User{}, %{email: "jane@example.com", password: "test"}) ]

    Enum.each(users, &Repo.insert!(&1))

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(v1_user_path(build_conn(), :index))
    |> json_response(200)

    expected = [
        %{ "email" => "john@example.com"},
        %{ "email" => "jane@example.com"}
    ]

    assert  Enum.map(response, &(Map.delete(&1, "id"))) == expected
  end
end