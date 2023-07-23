defmodule RustlerInline.MixProject do
  use Mix.Project

  def project do
    [
      app: :rustler_inline,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:rustler, "~> 0.29", only: :test},
      {:jason, "~> 1.4", only: :test},
      {:styler, "~> 0.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [generate_readme: &generate_readme/1]
  end

  defp generate_readme(_) do
    simple_example = File.read!("test/support/simple.ex")
    deps_example = File.read!("test/rustler_inline/extra_deps_test.exs")

    "README.eex"
    |> EEx.eval_file(simple_example: simple_example, deps_example: deps_example)
    |> then(&File.write("README.md", &1))
  end
end
