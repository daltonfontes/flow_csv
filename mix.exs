defmodule FlowCsv.MixProject do
  use Mix.Project

  def project do
    [
      app: :flow_csv,
      version: "0.1.0",
      elixir: "~> 1.17",
      description: "A concurrent and functional CSV parser built with Elixir.",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: [main: FlowCsv]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Dalton Fontes"],
      links: %{"GitHub" => "https://github.com/daltonfontes/flow_csv"}
    ]
  end
end
