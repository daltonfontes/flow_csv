defmodule FlowCsv.Streamer do
  @moduledoc """
  Manages stream reading and parallel processing.

  It uses `Task.async_stream` to process each line of the file in separate
  Elixir processes, ensuring that the core parsing (`FlowCsv.Parser`) is
  executed concurrently. This is a core demonstration of the BEAM concurrency model.
  """

  @doc """
  Divides the line stream into batches and uses Tasks for parallel processing.
  """
  @spec concurrent_process(Enumerable.t(), String.t()) :: Enumerable.t()
  def concurrent_process(line_stream, delimiter) do
    line_stream
    |> Task.async_stream(
      fn line ->
        FlowCsv.Parser.parse_line(line, delimiter)
      end,
      max_concurrency: System.schedulers_online() * 2,
      ordered: false
    )
    |> Stream.filter(fn {:ok, _} -> true end)
    |> Stream.map(fn {:ok, result} -> result end)
  end
end
