defmodule FlowCsv.Parser do
  @moduledoc """
  A simple CSV parser that can handle custom delimiters and quoted fields.
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
  # 1. End of Line
  # add of line, adds the last field
  defp parse(<<>>, current_field, fields, _delimiter, _state) do
    [current_field | fields]
  end

  # 2. Transation: Start of Quoted Field
  # RFC4180: if a field starts with a quote, it is a quoted field
  defp parse(<<"\"", rest::binary>>, current_field, fields, delimiter, :in_field)
       when current_field == "" do
    parse(rest, "", fields, delimiter, :in_quote)
  end

  # 3. Transation: Found Delimiter
  # RFC4180: Delimter terminates the unquoted field
  defp parse(<<c, rest::binary>>, curren_field, fields, delimiter, :in_field)
       when c == delimiter do
    parse(rest, "", [curren_field | fields], delimiter, :in_field)
  end

  # 4.Continuation: Normal Character in Field
  # RFC4180: appends the character to unquoted field
  defp parse(<<char::utf8, rest::binary>>, current_field, fields, delimiter, :in_field) do
    parse(rest, current_field <> <<char::utf8>>, fields, delimiter, :in_field)
  end

  # 5. Transition: Found Closing Quote
  # RFC4180: if we find a quote in quoted field, it may be the
  defp parse(<<"\"", rest::binary>>, current_field, fields, delimiter, :in_quote) do
    parse(rest, current_field, fields, delimiter, :quote_escape)
  end

  # 6. Continuation: Normal Character in Quoted Field
  # RFC4180: appends the character to quoted field
  defp parse(<<char::utf8, rest::binary>>, current_field, fields, delimiter, :in_quote) do
    parse(rest, current_field <> <<char::utf8>>, fields, delimiter, :in_quote)
  end

  # 7. Transition: Quote Escape
  # RFC4180: Escape rule for quotes inside quoted fields
  defp parse(<<"\"", rest::binary>>, current_field, fields, delimiter, :quote_escape) do
    parse(rest, current_field <> "\"", fields, delimiter, :in_quote)
  end

  # 8. Transition: Delimiter after Closing Quote
  # RFC4180: End of quoted field, next should be delimiter
  defp parse(<<c, rest::binary>>, current_field, fields, delimiter, :quote_escape)
       when c == delimiter do
    parse(rest, "", [current_field | fields], delimiter, :in_field)
  end

  # 9. Transition: End of Line after Closing Quote
  # RFC4180: End of quoted field at end of line
  defp parse(<<char::utf8, rest::binary>>, current_field, fields, delimiter, :quote_escape) do
    parse(rest, <<char::utf8>>, [current_field | fields], delimiter, :in_field)
  end
end
