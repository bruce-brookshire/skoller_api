defmodule Skoller.Verification do
  @moduledoc """
  Helper for verification code generation.
  """
  
  @doc """
  Generates a 5 digit verification code.

  ## Returns
  `String`
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