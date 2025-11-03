# FlowCSV

## Overview

FlowCSV is a high-performance CSV parsing library built entirely in Elixir.

It leverages streams and the BEAM Virtual Machine's concurrency model to process large CSV files line by line, ensuring:

- **Memory Efficiency**: Processing occurs via lazy streaming, never loading the entire file into memory at once.
- **Speed**: Utilizes native concurrency (Task.async_stream) to parse multiple lines in parallel.
- **Robustness**: The core parsing logic is a Deterministic Finite State Machine (FSM) implemented via Pattern Matching, ensuring pure and side-effect-free operations, adhering strictly to RFC 4180.

## Installation

If available in Hex, the package can be installed by adding `flow_csv` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flow_csv, "~> 0.1.0"}
  ]
end
```

Then, run `mix deps.get` to fetch the dependencies.

## Usage

The API is simple and direct, focused on pipeline composition. The main function, `FlowCSV.parse_file/2`, automatically manages file reading, concurrency, and type coercion.

### Quick Example

```elixir
# 1. Create a test file
{:ok, _} = File.write("data.csv", "name,age,price\nAlice,30,19.99\nBob,45,12.50\n\"Charlie, J.\",22,8.0")

# 2. Start the parsing pipeline
data_stream = "data.csv" |> FlowCSV.parse_file()

# 3. Collect the results (only for small files!)
data = Enum.to_list(data_stream)

# Result:
# [
#   ["name", "age", "price"],
#   ["Alice", 30, 19.99],
#   ["Bob", 45, 12.5],
#   ["Charlie, J.", 22, 8.0]
# ]

File.rm("data.csv")
```

### Stream Processing

For large files, avoid using `Enum.to_list`. Use the `Enumerable` output to continue the processing pipeline lazily:

```elixir
"large_data.csv"
|> FlowCSV.parse_file() # Returns a Stream
|> Stream.drop(1) # Skip the header
|> Stream.map(fn [name, age, price] ->
  # Process data without running out of memory
  %User{name: name, age: age, price: price}
end)
|> Stream.chunk_every(1000)
|> Enum.each(&MyRepo.insert_all/1) # Batch insert into the database
```

### Type Coercion (`coerce_types/1`)

FlowCSV automatically attempts to convert strings into Integer or Float.

| Input (String) | Output (Elixir Type) |
|----------------|---------------------|
| "100"          | 100 (Integer)       |
| "19.99"        | 19.99 (Float)       |
| "Product X"    | "Product X" (String)|
| ""             | "" (String)         |

## Contributing

Contributions are welcome! Please read our contribution guide before submitting a Pull Request.

1. Fork the project.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## License

Distributed under the MIT License. See `LICENSE.md` for more information.
