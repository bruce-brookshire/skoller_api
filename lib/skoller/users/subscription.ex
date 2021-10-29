defmodule Skoller.Users.Subscription do
  @moduledoc """
  The Users Trial context.
  """

  alias Skoller.Repo
  alias Skoller.Users.User

  import Ecto.Query

  @doc """
    Set user's lifetime_subscription to true.
  """
  def set_lifetime_subscription(%User{} = user) do
    from(u in User,
      where: u.id == ^user.id,
      update: [set: [lifetime_subscription: true, trial: false]]
    )
    |> Repo.update_all([])
  end



end