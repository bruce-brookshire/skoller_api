defmodule Skoller.Users.Trial do
  @moduledoc false

  import Ecto.Query

  alias Skoller.Users.User
  alias Skoller.Repo

  # @doc false
  def now?(%User{} = user) do
    user.trial_end != nil && DateTime.compare(user.trial_end, DateTime.utc_now) == :gt
  end

  # @doc false
  def cancel(id) do
    from(u in User,
      where: u.id == ^id,
      update: [set: [trial_end: nil]]
    )
    |> Repo.update_all([])
  end

  # @doc false
  def start_trial_for_all_users do
    from(u in User,
      where: is_nil(u.trial_end),
      update: [set:
        [
          trial: true,
          trial_start: datetime_add(^NaiveDateTime.utc_now, 0, "month"),
          trial_end: datetime_add(^NaiveDateTime.utc_now, +1, "month")
        ]
      ]
    )
    |> Repo.update_all([])
  end

  # @doc false
  def update_users_trial_status do
    from(u in User,
      where: u.trial_end > datetime_add(^NaiveDateTime.utc_now, 0, "month") and
             u.trial == false,
      update: [set: [trial: true]]
    )
    |> Repo.update_all([])

    from(u in User,
      where: (u.trial_end < datetime_add(^NaiveDateTime.utc_now, 0, "month") or
             is_nil(u.trial_end)) and
             u.trial == true,
      update: [set: [trial: false]]
    )
    |> Repo.update_all([])
  end
end
