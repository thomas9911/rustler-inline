defmodule RustlerInline.MixProject do
  use Mix.Project

  def project do
    [
      app: :rustler_inline,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
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
end
