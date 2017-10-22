defmodule HiveNode.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hivenode,
      version: "0.2.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      name: "HiveNode",
      source_url: "https://github.com/taran96/hivenode",
      docs: [main: "HiveNode",
             extras: ["README.md"]],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {HiveNode.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:logger_file_backend, "~> 0.0.10"},
      {:poison, "~> 3.1"},
      {:nerves_uart, "~> 0.1"},
      {:amqp, "~> 0.3.0"},
      {:distillery, "~> 1.5.1", runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
    ]
  end
end
