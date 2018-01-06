defmodule ClassnavapiWeb.Helpers.VerificationHelper do
  
  @moduledoc """
  
  Helper for verification code generation.

  """
  
  def generate_verify_code() do
    case :rand.uniform() do
      0.0 -> generate_verify_code()
      num -> num |> convert_rand() |> to_string()
    end
  end

  defp convert_rand(num) do
    case num < 1.0 do
      true -> convert_rand(num * 10)
      false -> Kernel.round(num * 10_000)
    end
  end
end