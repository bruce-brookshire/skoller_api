defmodule Skoller.Classes do

  alias Skoller.Repo
  alias Skoller.Schools.Class
  alias Skoller.Schools.ClassPeriod
  alias Skoller.Class.Status
  alias Skoller.Class.Doc
  alias Skoller.Class.Lock
  alias Skoller.Users.User
  alias Skoller.UserRole
  alias Skoller.Schools
  alias Skoller.Universities
  alias Skoller.HighSchools
  alias SkollerWeb.Helpers.StatusHelper
  alias SkollerWeb.Helpers.NotificationHelper

  import Ecto.Query

  @student_role 100

  @in_review_status 300
  @completed_status 700

  @diy_complete_lock 200

  @default_grade_scale %{"A" => "90", "B" => "80", "C" => "70", "D" => "60"}

  @doc """
  Gets a `Skoller.Schools.Class` by id.

  ## Examples

      iex> Skoller.Classes.get_class_by_id(1)
      {:ok, %Skoller.Schools.Class{}

  """
  def get_class_by_id(id) do
    Repo.get(Class, id)
  end

  @doc """
  Gets a `Skoller.Schools.Class` by id

  ## Examples

      iex> Skoller.Classes.get_class_by_id!(1)
      %Skoller.Schools.Class{}

  """
  def get_class_by_id!(id) do
    Repo.get!(Class, id)
  end

  @doc """
  Creates a `Skoller.Schools.Class` with changeset depending on `Skoller.Schools.School` tied to the `Skoller.Schools.ClassPeriod`

  ## Behavior:
   If there is no grade scale provided, a default is used: 

  ## Examples

      iex> Skoller.Classes.get_class_by_id!(1)
      %Skoller.Schools.Class{}

  """
  def create_class(%{"class_period_id" => class_period_id} = params, user) do
    params = params |> put_grade_scale()

    changeset = class_period_id
    |> Schools.get_school_from_period()
    |> get_create_changeset(params)
    |> add_student_created_class_fields(user)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:class, changeset)
    |> Ecto.Multi.run(:class_status, &StatusHelper.check_status(&1.class, %{params: params}))
    |> Repo.transaction()
  end

  def update_class(class_old, params) do
    changeset = class_old.class_period_id
    |> Schools.get_school_from_period()
    |> get_update_changeset(class_old, params)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:class, changeset)
    |> Ecto.Multi.run(:class_status, &StatusHelper.check_status(&1.class, nil))
    |> Repo.transaction()
  end

  @doc """
  Returns a count of `Skoller.Schools.Class` using the id of `Skoller.Schools.ClassPeriod`

  ## Examples

      iex> val = Skoller.Classes.get_class_count_by_period(1)
      ...> Kernel.is_integer(val)
      true

  """
  def get_class_count_by_period(period_id) do
    from(c in Class)
    |> where([c], c.class_period_id == ^period_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns the `Skoller.Class.Status` name and a count of `Skoller.Schools.Class` in the status

  ## Examples

      iex> Skoller.Classes.get_status_counts(1)
      [{status: name, count: num}]

  """
  def get_status_counts(school_id) do
    from(class in Class)
    |> join(:inner, [class], prd in ClassPeriod, class.class_period_id == prd.id)
    |> join(:full, [class, prd], status in Status, class.class_status_id == status.id)
    |> where([class, prd], prd.school_id == ^school_id)
    |> group_by([class, prd, status], [status.name])
    |> select([class, prd, status], %{status: status.name, count: count(class.id)})
    |> Repo.all()
  end

  @doc """
  Gets all `Skoller.Schools.Class` in a period that share a hash (hashed from syllabus url)

  ## Examples

      iex> Skoller.Classes.get_class_from_hash("123dadqwdvsdfscxsz", 1)
      [%Skoller.Schools.Class{}]

  """
  def get_class_from_hash(class_hash, period_id) do
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> where([class, period], period.id == ^period_id)
    |> where([class], class.class_upload_key == ^class_hash)
    |> Repo.all()
  end

  @doc """
  Gets class_id and school_id

  """
  def get_school_from_class_subquery(_params \\ %{})
  def get_school_from_class_subquery(%{"school_id" => school_id}) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> where([c, p], p.school_id == ^school_id)
    |> select([c, p], %{class_id: c.id, school_id: p.school_id})
  end
  def get_school_from_class_subquery(_params) do
    from(c in Class)
    |> join(:inner, [c], p in ClassPeriod, c.class_period_id == p.id)
    |> select([c, p], %{class_id: c.id, school_id: p.school_id})
  end

  def get_class_count(dates, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  def get_completed_class_count(dates, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.class_status_id == @completed_status)
    |> Repo.aggregate(:count, :id)
  end

  def get_class_in_review_count(dates, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.class_status_id != @completed_status and c.class_status_id >= @in_review_status)
    |> Repo.aggregate(:count, :id)
  end

  def student_created_count(dates, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.is_student_created == true)
    |> Repo.aggregate(:count, :id)
  end

  def classes_with_syllabus_subquery() do
    from(d in Doc)
    |> where([d], d.is_syllabus == true)
    |> distinct([d], d.class_id)
    |> order_by([d], asc: d.inserted_at)
  end

  def classes_completed_by_diy_count(dates, params) do
    from(c in Class)
    |> join(:inner, [c], cs in subquery(get_school_from_class_subquery(params)), c.id == cs.class_id)
    |> join(:inner, [c, cs], l in Lock, l.class_id == c.id and l.class_lock_section_id == @diy_complete_lock and l.is_completed == true)
    |> join(:inner, [c, cs, l], u in User, u.id == l.user_id)
    |> join(:inner, [c, cs, l, u], r in UserRole, r.user_id == u.id)
    |> where([c, cs, l, u, r], r.role_id == @student_role)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  def evaluate_class_completion(%Class{class_status_id: @completed_status}, %Class{class_status_id: @completed_status}), do: nil
  def evaluate_class_completion(%Class{class_status_id: _old_status}, %Class{class_status_id: @completed_status} = class) do
    Task.start(NotificationHelper, :send_class_complete_notification, [class])
  end
  def evaluate_class_completion(_old_class, _class), do: nil

  defp get_create_changeset(%{is_university: true}, params) do
    Universities.get_changeset(params)
  end
  defp get_create_changeset(%{is_university: false}, params) do
    HighSchools.get_changeset(params)
  end
  defp get_update_changeset(%{is_university: true}, params, old_class) do
    Universities.get_changeset(old_class, params)
  end
  defp get_update_changeset(%{is_university: false}, params, old_class) do
    HighSchools.get_changeset(old_class, params)
  end

  defp add_student_created_class_fields(changeset, %{student: nil}), do: changeset
  defp add_student_created_class_fields(changeset, %{student: _}) do
    changeset |> Ecto.Changeset.change(%{is_student_created: true})
  end
  defp add_student_created_class_fields(changeset, _user), do: changeset

  defp put_grade_scale(%{"grade_scale" => _} = params), do: params
  defp put_grade_scale(%{} = params) do
    params |> Map.put("grade_scale", @default_grade_scale)
  end
end