defmodule BTx.JRPC.Wallets.SendToAddress do
  @moduledoc """
  Send an amount to a given address.

  Requires wallet passphrase to be set with walletpassphrase call if wallet is
  encrypted.

  ## Schema fields (a.k.a "Arguments")

  - `:address` - (required) The bitcoin address to send to.

  - `:amount` - (required) The amount in BTC to send. eg 0.1

  - `:comment` - (optional) A comment used to store what the transaction is for.
    This is not part of the transaction, just kept in your wallet.

  - `:comment_to` - (optional) A comment to store the name of the person or
    organization to which you're sending the transaction. This is not part of
    the transaction, just kept in your wallet.

  - `:subtract_fee_from_amount` - (optional) The fee will be deducted from the
    amount being sent. The recipient will receive less bitcoins than you enter
    in the amount field. Defaults to `false`.

  - `:replaceable` - (optional) Allow this transaction to be replaced by a
    transaction with higher fees via BIP 125. Defaults to wallet default.

  - `:conf_target` - (optional) Confirmation target in blocks. Defaults to
    wallet `-txconfirmtarget`.

  - `:estimate_mode` - (optional) The fee estimate mode, must be one of (case
    insensitive): "unset" "economical" "conservative". Defaults to "unset".

  - `:avoid_reuse` - (optional) (only available if avoid_reuse wallet flag is
    set) Avoid spending from dirty addresses; addresses are considered dirty if
    they have previously been used in a transaction. Defaults to `true`.

  - `:fee_rate` - (optional) Specify a fee rate in sat/vB.

  - `:verbose` - (optional) If false, return a string, otherwise return a json
    object. Defaults to `false`.

  - `:wallet_name` - (optional) When is present, the `:wallet_name` is used
    to build the path for the request. See
    ["Wallet-specific RPC calls"][wallet-rpc] section for more information.

  [wallet-rpc]: http://hexdocs.pm/btx/BTx.JRPC.Wallets.html#module-wallet-specific-rpc-calls

  See [Bitcoin RPC API Reference `sendtoaddress`][sendtoaddress].
  [sendtoaddress]: https://developer.bitcoin.org/reference/rpc/sendtoaddress.html
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias BTx.JRPC.Request

  ## Types & Schema

  @typedoc "SendToAddress request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          address: String.t() | nil,
          amount: float() | nil,
          comment: String.t() | nil,
          comment_to: String.t() | nil,
          subtract_fee_from_amount: boolean(),
          replaceable: boolean() | nil,
          conf_target: non_neg_integer() | nil,
          estimate_mode: String.t(),
          avoid_reuse: boolean(),
          fee_rate: float() | nil,
          verbose: boolean()
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: "sendtoaddress"

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    field :address, :string
    field :amount, :float
    field :comment, :string
    field :comment_to, :string
    field :subtract_fee_from_amount, :boolean, default: false
    field :replaceable, :boolean
    field :conf_target, :integer
    field :estimate_mode, :string, default: "unset"
    field :avoid_reuse, :boolean, default: true
    field :fee_rate, :float
    field :verbose, :boolean, default: false
  end

  @required_fields ~w(address amount)a
  @optional_fields ~w(comment comment_to subtract_fee_from_amount replaceable
                      conf_target estimate_mode avoid_reuse fee_rate verbose
                      wallet_name)a

  # Valid estimate modes
  @valid_estimate_modes ~w(unset economical conservative)

  ## Encodable protocol

  defimpl BTx.JRPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          address: address,
          amount: amount,
          comment: comment,
          comment_to: comment_to,
          subtract_fee_from_amount: subtract_fee_from_amount,
          replaceable: replaceable,
          conf_target: conf_target,
          estimate_mode: estimate_mode,
          avoid_reuse: avoid_reuse,
          fee_rate: fee_rate,
          verbose: verbose,
          wallet_name: wallet_name
        }) do
      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: [
          address,
          amount,
          comment,
          comment_to,
          subtract_fee_from_amount,
          replaceable,
          conf_target,
          estimate_mode,
          avoid_reuse,
          fee_rate,
          verbose
        ]
      )
    end
  end

  ## API

  @doc """
  Creates a new `SendToAddress` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:sendtoaddress)
  end

  @doc """
  Creates a new `SendToAddress` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:sendtoaddress)
  end

  @doc """
  Creates a changeset for the `SendToAddress` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:address, min: 26, max: 90)
    |> valid_address_format()
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:conf_target, greater_than: 0)
    |> validate_number(:fee_rate, greater_than: 0)
    |> validate_inclusion(:estimate_mode, @valid_estimate_modes)
    |> validate_length(:wallet_name, min: 1, max: 64)
    |> validate_length(:comment, max: 1024)
    |> validate_length(:comment_to, max: 1024)
  end

  ## Private functions

  # Check if address contains only valid Bitcoin address characters
  defp valid_address_format(changeset) do
    validate_change(changeset, :address, fn :address, address ->
      # Bitcoin addresses use Base58 (legacy/P2SH) or Bech32 (segwit) character sets
      # This is a basic check - Bitcoin Core will do the comprehensive validation
      if String.match?(address, ~r/^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]+$/) or
           String.match?(address, ~r/^[a-z0-9]+$/) do
        []
      else
        [address: "is not a valid Bitcoin address"]
      end
    end)
  end
end
