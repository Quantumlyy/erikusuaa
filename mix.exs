defmodule Gateway.MixProject do
  use Mix.Project

  def project do
    [
      app: :gateway,
      version: "0.1.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Gateway.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gun, "~> 1.3"},

      {:amqp, "~> 1.6.0"},
      {:manifold, "~> 1.4"},

      {:xandra, "~> 0.13.1"},

      {:instruments, "~> 2.1"},

      {:recon, "~> 2.5.1", override: true},
      {:credo, "~> 1.5.1", only: [:dev, :test], runtime: false},
    ]
  end
end
