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
    load()
    |> Enum.each(fn class ->
      changes = Map.delete(class, :id) |> Map.to_list
      from(c in Class,
        where: c.id == ^class.id,
        update: [set: ^changes]
      )
      |> Repo.update_all([])
    end)
  end

  @doc """
    Load classes' trial premium and expired students count from db and stripe
  """
  def load do
    subscriptions = subscriptions()
    inactive_customers = inactive_customers(subscriptions)
    active_customers = active_customers(subscriptions)
    from(class in Class,
      left_join: student_class in StudentClass, on: class.id == student_class.class_id,
      left_join: student in Student, on: student.id == student_class.student_id,
      left_join: user in User, on: user.student_id == student.id,
      left_join: payment in Payment, on: user.id == payment.user_id,
      group_by: class.id,
      select: %{
        id: class.id,
        trial: fragment("sum(case when ? AND ? = ANY(?) then 0 when ? then 1 else 0 end)", user.trial, payment.customer_id, ^active_customers, user.trial),
        premium: fragment("sum(case when ? = ANY(?) then 1 else 0 end)", payment.customer_id, ^active_customers),
        expired: fragment("sum(case when ? then 0 when ? = ANY(?) then 1 else 0 end)", user.trial, payment.customer_id, ^inactive_customers)
      }
    )
    |> Repo.all()
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
