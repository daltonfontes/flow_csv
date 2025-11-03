defmodule FlowCsv.Parser do
  @moduledoc """
  Implements the Lexical Analyzer (Lexer) as a **Finite State Machine (FSM)**
  using Pattern Matching and Tail Call Optimization (TCO), **aligned with RFC 4180**.

  The FSM handles the complexity of quotes and delimiters, which are central
  rules of the CSV specification. Pattern Matching is used to clearly define
  state transitions (e.g., from `:in_field` to `:in_quote`).

  ## FSM States:
  * `:in_field`      -> Processing unquoted field.
  * `:in_quote`      -> Processing field INSIDE quotes. RFC 4180 allows line-breaks and delimiters in this state.
  * `:quote_escape`  -> Found a quote and is checking if it's an escape (`""`) or the end of the field followed by a delimiter.

  ## Examples (Doctests)
      iex> FlowCSV.Parser.parse_line("Name,\"Address with, comma\",Status")
      ["Name", "Address with, comma", "Status"]

      iex> FlowCSV.Parser.parse_line("\"Field with \"\"escaped quotes\"\"\",123", ",")
      ["Field with \"escaped quotes\"", "123"]
  """
  @doc """
  Start a recursive parsing of a CSV line.
  """
  @spec parse_line(String.t(), String.t()) :: [String.t()]
  def parse_line(line, delimiter \\ ",") do
    line
    |> String.trim()
    |> parse("", [], delimiter, :in_field)
    |> Enum.reverse()
  end

  # States:
  # 1. End of line (In any state)
  # End of line, adds the last field.
  defp parse(<<>>, current_field, fields, _delimiter, _state) do
    [current_field | fields]
  end

  # 2. Transition: Start of Quotes (In :in_field state, only if field is empty)
  # RFC 4180: If a field starts with a quote, the entire field MUST be quoted.
  defp parse(<<"\"", rest::binary>>, current_field, fields, delimiter, :in_field)
       when current_field == "" do
    parse(rest, "", fields, delimiter, :in_quote)
  end

  # 3. Transition: Found Delimiter (In :in_field state)
  # RFC 4180: Delimiter terminates the unquoted field.
  defp parse(<<char::utf8, rest::binary>>, current_field, fields, delimiter, :in_field)
       when <<char::utf8>> == delimiter do
    parse(rest, "", [current_field | fields], delimiter, :in_field)
  end

  # 4. Continuation: Normal Character (In :in_field state)
  # RFC 4180: Appends the character to the unquoted field.
  defp parse(<<char::utf8, rest::binary>>, current_field, fields, delimiter, :in_field) do
    parse(rest, current_field <> <<char::utf8>>, fields, delimiter, :in_field)
  end

  # 5. Transition: Found Closing Quote (In :in_quote state)
  # RFC 4180: Potential closing quote. Transitions to check state.
  defp parse(<<"\"", rest::binary>>, current_field, fields, delimiter, :in_quote) do
    parse(rest, current_field, fields, delimiter, :quote_escape)
  end

  # 6. Continuation: Normal Character (In :in_quote state)
  # RFC 4180: Allows any character (including delimiters) inside a quoted field.
  defp parse(<<char::utf8, rest::binary>>, current_field, fields, delimiter, :in_quote) do
    parse(rest, current_field <> <<char::utf8>>, fields, delimiter, :in_quote)
  end

  # 7. Transition: Quote Escape (In :quote_escape state)
  # RFC 4180: Escape rule - Two consecutive quotes (""). Appends one quote and returns to :in_quote.
  defp parse(<<"\"", rest::binary>>, current_field, fields, delimiter, :quote_escape) do
    parse(rest, current_field <> "\"", fields, delimiter, :in_quote)
  end

  # 8. Transition: Delimiter After Quote (In :quote_escape state)
  # RFC 4180: The quoted field ended, immediately followed by the delimiter.
  defp parse(<<char::utf8, rest::binary>>, current_field, fields, delimiter, :quote_escape)
       when <<char::utf8>> == delimiter do
    parse(rest, "", [current_field | fields], delimiter, :in_field)
  end

  # 9. Transition: Other Character After Quote (In :quote_escape state)
  # RFC 4180: Strictly, any character after the closing quote (except delimiter or EOL)
  # is invalid/error. Here, we maintain the robustness of a parser, treating it as the start of a new field.
  defp parse(<<char::utf8, rest::binary>>, current_field, fields, delimiter, :quote_escape) do
    parse(rest, <<char::utf8>>, [current_field | fields], delimiter, :in_field)
  end
end
