defmodule BTx.JRPC.Options do
  @moduledoc false
  # Options for the JSON RPC client.

  # Client opts
  client_opts = [
    base_url: [
      type: :string,
      required: false,
      default: "http://localhost:8332",
      doc: """
      The base URL of the Bitcoin server node.
      """
    ],
    username: [
      type: :string,
      required: false,
      default: "bitcoinuser",
      doc: """
      The username for the Bitcoin server node.
      """
    ],
    password: [
      type: :string,
      required: false,
      default: "bitcoinpass",
      doc: """
      The password for the Bitcoin server node.
      """
    ],
    headers: [
      type: {:list, {:tuple, [:string, :string]}},
      required: false,
      default: [
        {"user-agent", "btx-1.0"},
        {"content-type", "application/json"},
        {"accept", "application/json"}
      ],
      doc: """
      Additional headers to send with the request.
      """
    ],
    adapter: [
      type: {:custom, __MODULE__, :__validate_adapter__, []},
      type_doc: "`atom()` | `{atom(), keyword()}`",
      required: false,
      default: {Tesla.Adapter.Finch, name: BTx.Finch},
      doc: """
      The adapter to use for the HTTP client.
      """
    ]
  ]

  # RPC opts
  rpc_opts = [
    id: [
      type: :string,
      required: false,
      doc: """
      The ID for the RPC request.
      """
    ],
    path: [
      type: :string,
      required: false,
      doc: """
      Custom path for the JSON-RPC endpoint.

      > #### **Use with caution** {: .warning}
      >
      > When this option is present, it overrides the automatic path generation
      > from `:wallet_name` field in request schemas. Most wallet-specific RPC
      > methods automatically build the correct path when their `:wallet_name`
      > field is provided, which is the preferred approach. Only use this option
      > when you need to override the default path behavior. See the method
      > documentation to check if `:wallet_name` is supported before using this
      > option.
      """
    ]
  ]

  # Schema for the client opts
  @client_opts_schema NimbleOptions.new!(client_opts)

  # Schema for the RPC opts
  @rpc_opts_schema NimbleOptions.new!(rpc_opts)

  ## Docs API

  # coveralls-ignore-start

  @spec client_opts_docs() :: binary()
  def client_opts_docs do
    NimbleOptions.docs(@client_opts_schema)
  end

  @spec rpc_opts_docs() :: binary()
  def rpc_opts_docs do
    NimbleOptions.docs(@rpc_opts_schema)
  end

  # coveralls-ignore-stop

  ## Validators

  @spec validate_client_opts!(keyword()) :: keyword()
  def validate_client_opts!(opts) do
    NimbleOptions.validate!(opts, @client_opts_schema)
  end

  @spec validate_rpc_opts!(keyword()) :: keyword()
  def validate_rpc_opts!(opts) do
    NimbleOptions.validate!(opts, @rpc_opts_schema)
  end

  ## Validation helpers

  @spec __validate_adapter__(atom() | {atom(), keyword()}) :: {:ok, atom() | {atom(), keyword()}}
  def __validate_adapter__(adapter)

  def __validate_adapter__(adapter) when is_atom(adapter) do
    {:ok, adapter}
  end

  def __validate_adapter__({adapter, opts}) when is_atom(adapter) and is_list(opts) do
    {:ok, {adapter, opts}}
  end

  def __validate_adapter__(other) do
    {:error, "expected a module or a tuple {module, opts}, got: #{inspect(other)}"}
  end
end
