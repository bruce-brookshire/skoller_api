defmodule ClassnavapiWeb.Api.V1.UserControllerTest do
  use ClassnavapiWeb.ConnCase

  alias Classnavapi.Repo
  alias Classnavapi.User

  setup do
    {:ok, jwt, _} = Classnavapi.Auth.encode_and_sign(%{:id => 1}, %{typ: "access"})
    {:ok, %{jwt: jwt}}
  end

  test "index/2 responds with all Users", %{jwt: jwt} do
    john = User.changeset_insert(%User{}, %{email: "john@example.com", password: "test"})
    |> Repo.insert!
    
    jane = User.changeset_insert(%User{}, %{email: "jane@example.com", password: "test"})
    |> Repo.insert!

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(v1_user_path(build_conn(), :index))
    |> json_response(200)

    expected = [
        %{ "email" => "john@example.com", "id" => john.id},
        %{ "email" => "jane@example.com", "id" => jane.id}
    ]

    assert  response == expected
  end

  test "show/2 responds with a users id if the user is found", %{jwt: jwt} do
    user = User.changeset_insert(%User{}, %{email: "test@example.com", password: "test"})
    |> Repo.insert!

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(v1_user_path(build_conn(), :index))
    |> json_response(200)

    expected = [%{ "email" => "test@example.com", "id" => user.id}]

    assert  response == expected
  end
end