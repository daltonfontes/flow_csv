defmodule FlowCsv do
  @moduledoc """
  FlowCsv is a concurrent and functional CSV parser built with Elixir.

  It utilizes streams and the BEAM concurrency model to process
  large CSV files line by line, achieving memory efficiency
  and parallel execution. The core parsing logic is a Finite State Machine (FSM)
  implemented via Pattern Matching, ensuring purity and side-effect free operation.

  ## Example
      {:ok, pid} = File.write("data.csv", "name,age,price\nAlice,30,19.99\nBob,45,12.50\n\"Charlie\",22,8.0")

      data =
        "data.csv"
        |> FlowCSV.parse_file()
        |> Enum.to_list()

      # data is: [["name", "age", "price"], ["Alice", 30, 19.99], ["Bob", 45, 12.5], ["Charlie", 22, 8.0]]
      File.rm("data.csv")
  """

  @doc """
  Initiates the parsing pipeline for a file, applying concurrency and type coercion.
  """
  @spec parse_file(String.t(), String.t()) :: Enumerable.t()
  def parse_file(filepath, delimiter \\ ",") do
    filepath
    |> File.stream!()
    |> FlowCsv.Streamer.concurrent_process(delimiter)
    |> Stream.map(&FlowCsv.coerce_types/1)
  end

  @doc """
  Pure function to convert strings into Elixir types (Integer, Float, etc.).
  """
  @spec coerce_types([String.t()]) :: [any()]
  def coerce_types(fields) do
    Enum.map(fields, fn field ->
      case Integer.parse(field) do
        {int, ""} ->
          int

        _ ->
          case Float.parse(field) do
            {float, ""} -> float
            _ -> field
          end
      end
    end)
  end
end
