defmodule FlowCsvTest do
  use ExUnit.Case
  doctest FlowCsv

  test "parser handles simple non-quoted fields" do
    assert FlowCsv.Parser.parse_line("field1,field2,field3") == ["field1", "field2", "field3"]
  end

  test "parser handles commas inside quoted fields (RFC 4180)" do
    line = "value1,\"value with comma, here\",value3"
    expected = ["value1", "value with comma, here", "value3"]
    assert FlowCsv.Parser.parse_line(line) == expected
  end
end
