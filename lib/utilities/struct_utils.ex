defmodule StructUtils do

  def to_storeable_map(struct) do
    association_fields = struct.__struct__.__schema__(:associations)
    waste_fields = association_fields ++ [:__meta__]
    struct |> Map.from_struct |> Map.drop(waste_fields)
  end
  
end