defmodule Skoller.Users.Trial do
  @moduledoc false

  import Ecto.Query

  alias Skoller.Users.User
  alias Skoller.Repo

  # @doc false
  def now?(%User{} = user) do
    user.trial_end > DateTime.utc_now
  end

  # @doc false
  def start_trial_for_all_users do
    Skoller.Repo.update_all(
      User, set: [
        trial_start: DateTime.utc_now,
        trial_end: DateTime.utc_now |> DateTime.add(60*60*24*30)
      ]
    )
  end

  # @doc false
  def update_users_trial_status do
    from(u in User,
      where: u.trial_start < datetime_add(^NaiveDateTime.utc_now, 0, "month") and
             u.trial_end > datetime_add(^NaiveDateTime.utc_now, 0, "month"),
      update: [set: [trial: true]]
    )
    |> Repo.update_all([])

    from(u in User,
      where: u.trial_start > datetime_add(^NaiveDateTime.utc_now, 0, "month") or
             u.trial_end < datetime_add(^NaiveDateTime.utc_now, 0, "month"),
      update: [set: [trial: false]]
    )
    |> Repo.update_all([])

    IO.puts("Trial statuses updated")
  end
end
