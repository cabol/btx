defmodule BTx.MixProject do
  use Mix.Project

  @source_url "https://github.com/cabol/btx"
  @version "0.1.0"

  def project do
    [
      app: :btx,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: Mix.env() != :test,
      aliases: aliases(),
      deps: deps(),

      # Testing
      test_coverage: [tool: ExCoveralls, export: "test-coverage"],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        "test.ci": :test
      ],

      # Dialyzer
      dialyzer: dialyzer(),

      # Hex
      description: "Bitcoin Toolkit for Elixir",
      package: package(),

      # Docs
      name: "BTx",
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {BTx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Required
      {:tesla, "~> 1.14"},
      {:finch, "~> 0.20"},
      {:jason, "~> 1.4"},
      {:ecto, "~> 3.13"},
      {:nimble_options, "~> 0.5 or ~> 1.0"},
      {:telemetry, "~> 0.4 or ~> 1.0"},

      # Test & Code Analysis
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
      {:mimic, "~> 2.0", only: :test},

      # Benchmark Test
      {:benchee, "~> 1.4", only: [:dev, :test]},
      {:benchee_html, "~> 1.0", only: [:dev, :test]},

      # Docs
      {:ex_doc, "~> 0.38", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      bench: "run benchmarks/benchmark.exs",
      "test.ci": [
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "coveralls.html",
        "sobelow --skip --exit Low",
        "dialyzer --format short"
      ]
    ]
  end

  defp package do
    [
      name: :nebulex,
      maintainers: [
        "Carlos Bolanos",
        "Felipe Ripoll"
      ],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      },
      files: ~w(lib .formatter.exs mix.exs README* CHANGELOG* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "BTx",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/btx",
      source_url: @source_url,
      extra_section: "GUIDES",
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: [
        # BTx,
        # BTx.RPC,
        # BTx.RPC.Encodable,
        # BTx.RPC.Request,
        # BTx.RPC.Response,

        "RPC APIs": [
          BTx.RPC.Blockchain,
          BTx.RPC.Mining,
          BTx.RPC.Wallets
        ],
        "Blockchain RPCs": [
          BTx.RPC.Blockchain.GetMempoolEntry,
          BTx.RPC.Blockchain.GetMempoolEntryFees,
          BTx.RPC.Blockchain.GetMempoolEntryResult
        ],
        "Mining RPCs": [
          BTx.RPC.Mining.GenerateToAddress
        ],
        "Wallet RPCs": [
          BTx.RPC.Wallets.CreateWallet,
          BTx.RPC.Wallets.CreateWalletResult,
          BTx.RPC.Wallets.GetAddressInfo,
          BTx.RPC.Wallets.GetAddressInfoResult,
          BTx.RPC.Wallets.GetBalance,
          BTx.RPC.Wallets.GetNewAddress,
          BTx.RPC.Wallets.GetReceivedByAddress,
          BTx.RPC.Wallets.GetTransaction,
          BTx.RPC.Wallets.GetTransactionResult,
          BTx.RPC.Wallets.GetWalletInfo,
          BTx.RPC.Wallets.GetWalletInfoResult,
          BTx.RPC.Wallets.ListTransactions,
          BTx.RPC.Wallets.ListTransactionsItem,
          BTx.RPC.Wallets.ListUnspent,
          BTx.RPC.Wallets.ListUnspentItem,
          BTx.RPC.Wallets.ListWallets,
          BTx.RPC.Wallets.LoadWallet,
          BTx.RPC.Wallets.LoadWalletResult,
          BTx.RPC.Wallets.SendToAddress,
          BTx.RPC.Wallets.SendToAddressResult,
          BTx.RPC.Wallets.UnloadWallet,
          BTx.RPC.Wallets.UnloadWalletResult,
          BTx.RPC.Wallets.WalletPassphrase
        ],
        Exceptions: [
          BTx.RPC.Error,
          BTx.RPC.MethodError
        ]
      ]
    ]
  end

  defp extras do
    [
      # Introduction
      # "guides/introduction/getting-started.md"
    ]
  end

  defp groups_for_extras do
    [
      Introduction: ~r{guides/introduction/[^\/]+\.md},
      Learning: ~r{guides/learning/[^\/]+\.md}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix, :telemetry, :ex_unit],
      plt_file: {:no_warn, "priv/plts/" <> plt_file_name()},
      flags: [
        :unmatched_returns,
        :error_handling,
        :no_opaque,
        :unknown,
        :no_return
      ]
    ]
  end

  defp plt_file_name do
    "dialyzer-#{Mix.env()}-#{System.otp_release()}-#{System.version()}.plt"
  end
end
