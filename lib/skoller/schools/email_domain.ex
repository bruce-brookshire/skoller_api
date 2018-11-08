defmodule Skoller.Schools.EmailDomain do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "school_email_domains" do
    field :email_domain, :string
    field :school_id, :id

    timestamps()
  end

  @req_fields [:school_id, :email_domain]
  @all_fields @req_fields

  @doc false
  def changeset(email_domain, attrs) do
    email_domain
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> update_change(:email_domain, &get_last_section_of_email_domain(&1))
  end

  defp get_last_section_of_email_domain(domain) do
    domain
    |> String.split(".", trim: true)
    |> get_last_two_elements()
    |> Enum.intersperse(".")
    |> List.to_string()
  end

  defp get_last_two_elements(list) do
    len = length(list)
    Enum.slice((len - 2)..(len - 1))
  end
end
