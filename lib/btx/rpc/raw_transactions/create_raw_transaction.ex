defmodule BTx.RPC.RawTransactions.CreateRawTransaction do
  @moduledoc """
  Create a transaction spending the given inputs and creating new outputs.

  Outputs can be addresses or data.

  Returns hex-encoded raw transaction.

  Note that the transaction's inputs are not signed, and it is not stored in the
  wallet or transmitted to the network.

  ## Schema fields (a.k.a "Arguments")

  - `:inputs` - (required) Array of inputs to spend. Each input must have a txid
    and vout, with an optional sequence number.

  - `:outputs` - (required) Array of outputs to create. Can contain address outputs
    (sending Bitcoin to addresses) and/or data outputs (embedding hex data).

  - `:locktime` - (optional) Raw locktime. Non-0 value also locktime-activates inputs.
    Default: 0.

  - `:replaceable` - (optional) Marks this transaction as BIP125-replaceable.
    Allows this transaction to be replaced by a transaction with higher fees.
    Default: false.

  See [Bitcoin RPC API Reference `createrawtransaction`][createrawtransaction].
  [createrawtransaction]: https://developer.bitcoin.org/reference/rpc/createrawtransaction.html
  """

  use Ecto.Schema

  import BTx.Helpers, only: [trim_trailing_nil: 1]
  import Ecto.Changeset

  alias BTx.RPC.Request
  alias BTx.RPC.RawTransactions.RawTransaction.{Input, Output, Output.Address}

  ## Constants

  @method "createrawtransaction"

  ## Types & Schema

  @typedoc "CreateRawTransaction request"
  @type t() :: %__MODULE__{
          method: String.t(),
          inputs: [Input.t()] | nil,
          outputs: [map()] | nil,
          locktime: non_neg_integer() | nil,
          replaceable: boolean() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: @method

    # Method fields
    embeds_many :inputs, Input
    embeds_one :outputs, Output
    field :locktime, :integer, default: 0
    field :replaceable, :boolean, default: false
  end

  @optional_fields ~w(locktime replaceable)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          inputs: inputs,
          outputs: outputs,
          locktime: locktime,
          replaceable: replaceable
        }) do
      # Convert inputs to simple maps for JSON encoding
      input_params = Enum.map(inputs, &input_to_map/1)

      # Convert outputs to the format expected by Bitcoin Core
      output_params = output_to_map(outputs)

      params = [input_params, output_params, locktime, replaceable]

      Request.new(
        method: method,
        path: "/",
        params: trim_trailing_nil(params)
      )
    end

    defp input_to_map(%Input{txid: txid, vout: vout, sequence: sequence}) do
      %{
        "txid" => txid,
        "vout" => vout,
        "sequence" => sequence
      }
      |> Map.reject(fn {_k, v} -> is_nil(v) end)
    end

    defp output_to_map(%Output{addresses: addresses, data: data}) do
      init_acc = if data, do: [%{"data" => data}], else: []

      Enum.reduce(addresses, init_acc, fn %Address{address: addr, amount: amnt}, acc ->
        [%{addr => amnt} | acc]
      end)
    end
  end

  ## API

  @doc """
  Creates a new `CreateRawTransaction` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:createrawtransaction)
  end

  @doc """
  Creates a new `CreateRawTransaction` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:createrawtransaction)
  end

  @doc """
  Creates a changeset for the `CreateRawTransaction` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @optional_fields)
    |> cast_embed(:inputs, required: true)
    |> cast_embed(:outputs, required: true)
    |> validate_number(:locktime, greater_than_or_equal_to: 0)
  end
end
