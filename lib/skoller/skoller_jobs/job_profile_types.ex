defmodule Skoller.SkollerJobs.JobProfileStatus do
  use Ecto.Schema

  schema "job_profile_statuses" do
    field :name, :string
  end
end

defmodule Skoller.SkollerJobs.EthnicityType do
  use Ecto.Schema

  schema "ethnicity_types" do
    field :name, :string
  end
end

defmodule Skoller.SkollerJobs.JobCandidateActivityType do
  use Ecto.Schema

  schema "job_candidate_activity_types" do
    field :name, :string
  end
end

defmodule Skoller.SkollerJobs.DegreeType do
  use Ecto.Schema

  schema "degree_types" do
    field :name, :string
  end
end
