defmodule Skoller.Users.Trial do
  @moduledoc """
  The Users Trial context.
  """

  alias Skoller.Repo
  alias Skoller.Users.User

  import Ecto.Query

  @doc """
    Check if the user is on a trial.
  """
  def now?(%User{} = user) do
    user.trial_end != nil && DateTime.compare(user.trial_end, DateTime.utc_now()) == :gt
  end

  @doc """
    Days left for a trial end
  """
  def days_left(%User{} = user) do
    user.trial_end && DateTime.diff(user.trial_end, DateTime.utc_now()) / 60 / 60 / 24
  end

  @doc """
    Cancel a user's trial.
  """
  def cancel(%User{} = user) do
    from(u in User,
      where: u.id == ^user.id,
      update: [set: [trial_end: nil, lifetime_trial: false]]
    )
    |> Repo.update_all([])
  end

  @doc """
    Expire user's trial
  """
  def expire(%User{} = user) do
    from(u in User,
      where: u.id == ^user.id,
      update: [set: [trial_end: datetime_add(^NaiveDateTime.utc_now(), 0, "month"), trial: false]]
    )
    |> Repo.update_all([])
  end

  @doc """
    Start trial for all users with trial_end: nil
  """
  def start_trial_for_all_users do
    from(u in User,
      where: is_nil(u.trial_end),
      update: [
        set: [
          trial: true,
          trial_start: datetime_add(^NaiveDateTime.utc_now(), 0, "month"),
          trial_end: datetime_add(^NaiveDateTime.utc_now(), 30, "day")
        ]
      ]
    )
    |> Repo.update_all([])
  end

  @doc """
    Update users' trial status in db, used for cronjob
  """
  def update_users_trial_status do
    from(u in User,
      where:
        u.trial_end > datetime_add(^NaiveDateTime.utc_now(), 0, "month") and
          u.trial == false,
      update: [set: [trial: true]]
    )
    |> Repo.update_all([])

    from(u in User,
      where:
        (u.trial_end < datetime_add(^NaiveDateTime.utc_now(), 0, "month") or
           is_nil(u.trial_end)) and
          u.trial == true,
      update: [set: [trial: false]]
    )
    |> Repo.update_all([])
  end

  @doc """
    start endless trial for specific user
  """
  def set_endless_trial(%User{} = user) do
    from(u in User,
      where: u.id == ^user.id,
      update: [
        set: [
          trial: true,
          lifetime_trial: true,
          trial_start: datetime_add(^NaiveDateTime.utc_now(), 0, "month"),
          trial_end: datetime_add(^NaiveDateTime.utc_now(), 100, "year")
        ]
      ]
    )
    |> Repo.update_all([])
  end
end
