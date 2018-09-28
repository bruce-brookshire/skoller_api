defmodule Skoller.UserReports do
  @moduledoc """
  A context module for user reports.
  """

  alias Skoller.Repo
  alias Skoller.UserReports.Report

  import Ecto.Query

  @doc """
  Reports a user

  ## Returns
  `{:ok, Skoller.UserReports.Report}` or `{:error, Ecto.Changeset}`
  """
  def report_user(params) do
    %Report{}
    |> Report.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Marks a report as complete (i.e. read and action taken)

  ## Returns
  `{:ok, Skoller.UserReports.Report}` or `{:error, Ecto.Changeset}`
  """
  def complete_report(id) do
    Repo.get!(Report, id)
    |> Ecto.Changeset.change(%{is_complete: true})
    |> Repo.update()
  end

  @doc """
  Gets a list of reports that have not been completed

  ## Returns
  `[Skoller.UserReports.Report]` or `[]`
  """
  def get_incomplete_reports() do
    from(r in Report)
    |> where([r], r.is_complete == false)
    |> Repo.all()
  end
end