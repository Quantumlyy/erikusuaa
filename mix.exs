defmodule Erikusuaa.MixProject do
  use Mix.Project

  def project do
    [
      app: :erikusuaa,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Erikusuaa.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # region interactivity
      {:gun, "~> 1.3"},
      {:poison, "~> 4.0"},
      # endregion interactivity

      # region service communication
      {:amqp, "~> 1.6.0"},
      # endregion service communication

      # region process communication
      {:manifold, "~> 1.4"},
      # endregion process communication

      # region caching
      {:xandra, "~> 0.13.1"},
      # endregion cachine

      # region stats tracking
      {:instruments, "~> 2.1"},
      {:recon, "~> 2.5.1", override: true},
      # endregion stats tracking

      {:credo, "~> 1.5.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end
end
