defmodule BTx.RPC.RawTransactions.FundRawTransaction do
  @moduledoc """
  If the transaction has no inputs, they will be automatically selected to meet
  its out value.

  It will add at most one change output to the outputs.

  No existing outputs will be modified unless "subtractFeeFromOutputs" is
  specified.

  Note that inputs which were signed may need to be resigned after completion
  since in/outputs have been added.

  The inputs added will not be signed, use `signrawtransactionwithkey` or
  `signrawtransactionwithwallet` for that.

  Note that all existing inputs must have their previous output transaction be
  in the wallet.

  ## Schema fields (a.k.a "Arguments")

  - `:hexstring` - (required) The hex string of the raw transaction.

  - `:options` - (optional) Funding options for the transaction.

  - `:iswitness` - (optional) Whether the transaction hex is a serialized
    witness transaction. If `iswitness` is not present, heuristic tests will be
    used in decoding.

  See [Bitcoin RPC API Reference `fundrawtransaction`][fundrawtransaction].
  [fundrawtransaction]: https://developer.bitcoin.org/reference/rpc/fundrawtransaction.html
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import BTx.Helpers, only: [trim_trailing_nil: 1]
  import Ecto.Changeset

  alias BTx.RPC.RawTransactions.FundRawTransaction.Options
  alias BTx.RPC.Request

  ## Constants

  @method "fundrawtransaction"

  ## Types & Schema

  @typedoc "FundRawTransaction request"
  @type t() :: %__MODULE__{
          method: String.t(),
          wallet_name: String.t() | nil,
          hexstring: String.t() | nil,
          options: Options.t() | nil,
          iswitness: boolean() | nil
        }

  @primary_key false
  embedded_schema do
    # Predefined fields
    field :method, :string, default: @method

    # For optional path parameter `/wallet/<wallet_name>`
    field :wallet_name, :string

    # Method fields
    field :hexstring, :string
    embeds_one :options, Options
    field :iswitness, :boolean
  end

  @required_fields ~w(hexstring)a
  @optional_fields ~w(iswitness wallet_name)a

  ## Encodable protocol

  defimpl BTx.RPC.Encodable, for: __MODULE__ do
    def encode(%{
          method: method,
          hexstring: hexstring,
          options: options,
          iswitness: iswitness,
          wallet_name: wallet_name
        }) do
      # Convert options to map for JSON encoding
      options_params = if options, do: Options.to_map(options), else: nil

      params = [hexstring, options_params, iswitness]

      path = if wallet_name, do: "/wallet/#{wallet_name}", else: "/"

      Request.new(
        method: method,
        path: path,
        params: trim_trailing_nil(params)
      )
    end
  end

  ## API

  @doc """
  Creates a new `FundRawTransaction` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:fundrawtransaction)
  end

  @doc """
  Creates a new `FundRawTransaction` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:fundrawtransaction)
  end

  @doc """
  Creates a changeset for the `FundRawTransaction` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:options)
    |> validate_length(:hexstring, min: 1)
    |> validate_hexstring(:hexstring)
  end
end
