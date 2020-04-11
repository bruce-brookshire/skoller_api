defmodule Skoller.Changeset do
  defmacro __using__(options) do
    option_map = Map.new(options)
    expand_or_return = fn 
      value when is_list(value) -> value 
      value -> Macro.expand(value, __CALLER__)
    end
    
    req_fields = (option_map[:req_fields] || []) |> expand_or_return.()
    opt_fields = (option_map[:opt_fields] || []) |> expand_or_return.()
    all_fields = req_fields ++ opt_fields

    parent_module = __CALLER__.context_modules |> List.first()

    quote do
      import Ecto.Changeset

      def insert_changeset(params) do
        unquote(parent_module)
        |> apply(:__struct__, [%{}])
        |> changeset(params)
      end

      def changeset(%unquote(parent_module){} = changeset, params) do
        changeset 
        |> cast(params, unquote(all_fields)) 
        |> validate_required(unquote(all_fields))
      end

      defoverridable [insert_changeset: 1]
      defoverridable [changeset: 2]
    end
  end

  @moduledoc """
  A module for manipulating `Ecto.Changeset`
  """

  import Ecto.Changeset

  @doc """
  Deletes all tuples in `keyword` from the changeset.
  """
  def delete_changes(changeset, keyword) do
    keyword |> Enum.reduce(changeset, & &2 |> delete_change(elem(&1, 0)))
  end

  @doc """
  Returns a `Keyword` of `changeset.changes` that do not exist in `original`
  """
  def get_new_changes(changeset, original) do
    changeset.changes
    |> Map.to_list()
    |> Enum.filter(&old_field_not_set(&1, original))
    |> convert_keyword_to_map()
  end

  defp convert_keyword_to_map(keyword) do
    keyword |> Enum.reduce(%{}, & &2 |> Map.put(elem(&1, 0), elem(&1, 1)))
  end

  defp old_field_not_set(tuple, original) do
    original |> Map.get(elem(tuple, 0)) |> is_nil()
  end
end