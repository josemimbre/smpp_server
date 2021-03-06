defmodule SmppServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :smpp_server,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SmppServer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:smppex, "~> 2.0"},
      {:distillery, "~> 1.5", runtime: false}
    ]
  end
end
