defmodule Skoller.Classes.StudentsCount do
  @moduledoc """
  The StudentsCount context.
  """

  alias Skoller.Repo
  alias Skoller.Users.User
  alias Skoller.Classes.Class
  alias Skoller.Students.Student
  alias Skoller.Payments.Stripe, as: Payment
  alias Skoller.StudentClasses.StudentClass

  import Ecto.Query

  @doc """
    Update classes' trial premium and expired students count
  """
  def update_all do
    stream = load() |> Stream.each(fn changes ->
      updates = Enum.to_list(changes.data)
      changes.ids
      |> Enum.chunk_every(20)
      |> Enum.each(fn ids ->
        from(c in Class,
          where: c.id in ^ids,
          update: [set: ^updates]
        )
        |> Repo.update_all([])
      end)
    end)
    Repo.transaction(fn() ->
      stream |> Stream.run()
    end, timeout: 20_000_000)
  end

  @doc """
    Load classes' trial premium and expired students count from db and stripe
  """
  def load do
    subscriptions = subscriptions()
    inactive_customers = inactive_customers(subscriptions)
    active_customers = active_customers(subscriptions)
    subquery = from(class in Class,
      left_join: student_class in StudentClass, on: class.id == student_class.class_id,
      left_join: student in Student, on: student.id == student_class.student_id,
      left_join: user in User, on: user.student_id == student.id,
      left_join: payment in Payment, on: user.id == payment.user_id,
      group_by: class.id,
      select: %Skoller.Classes.Class{
        id: class.id,
        trial: fragment("sum(case when ? AND ? = ANY(?) then 0 when ? then 1 else 0 end)", user.trial, payment.customer_id, ^active_customers, user.trial),
        premium: fragment("sum(case when ? = ANY(?) then 1 else 0 end)", payment.customer_id, ^active_customers),
        expired: fragment("sum(case when ? then 0 when ? = ANY(?) then 1 else 0 end)", user.trial, payment.customer_id, ^inactive_customers)
      }
    )
    from(e in subquery(subquery),
      group_by: [e.trial, e.premium, e.expired],
      select: %{
        ids: fragment("ARRAY_AGG(?)", e.id),
        data: %{
          trial: e.trial, premium: e.premium, expired: e.expired
        }
      }
    )
    |> Repo.stream()
  end

  @doc """
    Load subscriptions from stripe
  """
  defp subscriptions do
    {:ok, %Stripe.List{data: subscriptions}} = Stripe.Subscription.list(%{status: "all"})
    subscriptions
  end

  @doc """
    Filter active customers from subscriptions
  """
  defp active_customers(subscriptions) do
    subscriptions
    |> Enum.reject(&(&1.status != "active"))
    |> Enum.map(&(&1.customer))
  end

  @doc """
    Filter inactive customers from subscriptions
  """
  defp inactive_customers(subscriptions) do
    subscriptions
    |> Enum.reject(&(&1.status == "active"))
    |> Enum.map(&(&1.customer))
  end
end
