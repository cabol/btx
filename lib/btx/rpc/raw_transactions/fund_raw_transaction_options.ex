defmodule BTx.RPC.RawTransactions.FundRawTransaction.Options do
  @moduledoc """
  Options for the `fundrawtransaction` JSON RPC API.

  This schema describes the various options available when funding a raw
  transaction.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "FundRawTransaction Options"
  @type t() :: %__MODULE__{
          add_inputs: boolean() | nil,
          change_address: String.t() | nil,
          change_position: integer() | nil,
          change_type: String.t() | nil,
          include_watching: boolean() | nil,
          lock_unspents: boolean() | nil,
          fee_rate: float() | nil,
          fee_rate_btc: float() | nil,
          subtract_fee_from_outputs: [integer()] | nil,
          replaceable: boolean() | nil,
          conf_target: integer() | nil,
          estimate_mode: String.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :add_inputs, :boolean, default: true
    field :change_address, :string
    field :change_position, :integer
    field :change_type, :string
    field :include_watching, :boolean
    field :lock_unspents, :boolean, default: false
    field :fee_rate, :float
    field :fee_rate_btc, :float
    field :subtract_fee_from_outputs, {:array, :integer}, default: []
    field :replaceable, :boolean
    field :conf_target, :integer
    field :estimate_mode, :string
  end

  # Valid change types
  @valid_change_types ~w(legacy p2sh-segwit bech32)
  # Valid estimate modes
  @valid_estimate_modes ~w(unset economical conservative)

  @optional_fields ~w(add_inputs change_address change_position change_type
                      include_watching lock_unspents fee_rate fee_rate_btc
                      subtract_fee_from_outputs replaceable conf_target
                      estimate_mode)a

  ## API

  @doc """
  Creates a changeset for the `FundRawTransaction.Options` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(options, attrs) do
    options
    |> cast(normalize_attrs(attrs), @optional_fields, empty_values: [])
    |> validate_inclusion(:change_type, @valid_change_types)
    |> validate_number(:change_position, greater_than_or_equal_to: 0)
    |> validate_fee_rates()
    |> validate_subtract_fee_from_outputs()
    |> validate_number(:conf_target, greater_than: 0)
    |> validate_inclusion(:estimate_mode, @valid_estimate_modes)
    |> valid_address_format(:change_address)
  end

  @doc """
  Converts options to a map for JSON encoding.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = options) do
    options
    |> Map.take(__schema__(:fields))
    |> Enum.reduce(%{}, fn
      {:change_address, val}, acc when not is_nil(val) ->
        Map.put(acc, "changeAddress", val)

      {:change_position, val}, acc when not is_nil(val) ->
        Map.put(acc, "changePosition", val)

      {:include_watching, val}, acc when not is_nil(val) ->
        Map.put(acc, "includeWatching", val)

      {:lock_unspents, val}, acc when not is_nil(val) ->
        Map.put(acc, "lockUnspents", val)

      {:fee_rate, val}, acc when not is_nil(val) ->
        Map.put(acc, "fee_rate", val)

      {:fee_rate_btc, val}, acc when not is_nil(val) ->
        Map.put(acc, "feeRate", val)

      {:subtract_fee_from_outputs, val}, acc when not is_nil(val) ->
        Map.put(acc, "subtractFeeFromOutputs", val)

      {key, val}, acc when not is_nil(val) ->
        Map.put(acc, to_string(key), val)

      _, acc ->
        acc
    end)
  end

  ## Private functions

  defp validate_fee_rates(changeset) do
    changeset
    |> validate_number(:fee_rate, greater_than: 0)
    |> validate_number(:fee_rate_btc, greater_than: 0)
    |> validate_exclusive_fee_rates()
  end

  defp validate_exclusive_fee_rates(changeset) do
    fee_rate = get_field(changeset, :fee_rate)
    fee_rate_btc = get_field(changeset, :fee_rate_btc)

    case {fee_rate, fee_rate_btc} do
      {nil, nil} -> changeset
      {_, nil} -> changeset
      {nil, _} -> changeset
      {_, _} -> add_error(changeset, :fee_rate, "cannot specify both fee_rate and fee_rate_btc")
    end
  end

  defp validate_subtract_fee_from_outputs(changeset) do
    validate_change(changeset, :subtract_fee_from_outputs, fn :subtract_fee_from_outputs, outputs ->
      if Enum.all?(outputs, &(&1 >= 0)) do
        []
      else
        [subtract_fee_from_outputs: "all output indices must be non-negative"]
      end
    end)
  end
end
