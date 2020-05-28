defmodule SkollerWeb.Api.V1.Organization.InsightsUserController do
  alias Skoller.Repo
  alias Skoller.Users
  alias Skoller.Users.User
  alias SkollerWeb.UserView
  alias Skoller.UserRoles.UserRole
  alias Skoller.Services.SesMailer
  alias Skoller.Organizations.OrgOwners
  alias SkollerWeb.Responses.MultiError

  import Ecto.Query
  import SkollerWeb.Plugs.Auth

  use SkollerWeb, :controller

  @admin_role 200
  @insights_role 700
  @chars "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.split("")

  plug :verify_role, %{roles: [@admin_role, @insights_role]}

  def create(%{assigns: %{user: %{email: invited_by}}} = conn, %{"email" => email}) do
    password = generate_password()

    require Logger
    Logger.info("User password: " <> password)

    user_params = %{
      roles: [@insights_role],
      email: email,
      password: password
    }

    case Users.create_user(user_params, admin: true) do
      {:ok, user} ->
        send_insights_email(user_params, invited_by)

        conn
        |> put_view(UserView)
        |> render("show.json", user: user)

      {:error, failed_value} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def index(conn, params) do
    offset = params["offset"] || 0

    from(u in User)
    |> join(:inner, [u], r in UserRole, on: u.id == r.user_id)
    |> where([u, r], r.role_id == @insights_role)
    |> filters(params)
    |> select([u, r], u)
    |> offset(^offset)
    |> limit(15)
    |> preload([:org_owners, :org_members, :roles])
    |> Repo.all()
    |> case do
      users when is_list(users) ->
        conn
        |> put_view(UserView)
        |> render("index.json", users: users)

      _ ->
        send_resp(conn, 422, "Unprocessable Entity")
    end
  end

  defp filters(query, %{"email" => email}),
    do: where(query, [u, r], ilike(u.email, ^"%#{email}%"))

  defp filters(query, _), do: query

  defp generate_password(), do: for(_i <- 1..12, do: Enum.random(@chars)) |> Enum.join()

  defp send_insights_email(%{email: email, password: password}, invited_by) do
    SesMailer.send_individual_email(
      %{to: email, form: %{email: email, password: password, invited_by: invited_by}},
      "new_insights_account"
    )
  end
end
