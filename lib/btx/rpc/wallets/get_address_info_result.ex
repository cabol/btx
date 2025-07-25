defmodule BTx.RPC.Wallets.GetAddressInfoResult do
  @moduledoc """
  Result from the `getaddressinfo` JSON RPC API.

  Contains detailed information about a Bitcoin address.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Response

  ## Types & Schema

  @typedoc "GetAddressInfoResult"
  @type t() :: %__MODULE__{
          address: String.t() | nil,
          script_pub_key: String.t() | nil,
          ismine: boolean() | nil,
          iswatchonly: boolean() | nil,
          solvable: boolean() | nil,
          desc: String.t() | nil,
          isscript: boolean() | nil,
          ischange: boolean() | nil,
          iswitness: boolean() | nil,
          witness_version: non_neg_integer() | nil,
          witness_program: String.t() | nil,
          script: String.t() | nil,
          hex: String.t() | nil,
          pubkeys: [String.t()],
          sigsrequired: non_neg_integer() | nil,
          pubkey: String.t() | nil,
          embedded: map() | nil,
          iscompressed: boolean() | nil,
          timestamp: non_neg_integer() | nil,
          hdkeypath: String.t() | nil,
          hdseedid: String.t() | nil,
          hdmasterfingerprint: String.t() | nil,
          labels: [String.t()]
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :address, :string
    field :script_pub_key, :string
    field :ismine, :boolean
    field :iswatchonly, :boolean
    field :solvable, :boolean
    field :desc, :string
    field :isscript, :boolean
    field :ischange, :boolean
    field :iswitness, :boolean
    field :witness_version, :integer
    field :witness_program, :string
    field :script, :string
    field :hex, :string
    field :pubkeys, {:array, :string}, default: []
    field :sigsrequired, :integer
    field :pubkey, :string
    field :embedded, :map
    field :iscompressed, :boolean
    field :timestamp, :integer
    field :hdkeypath, :string
    field :hdseedid, :string
    field :hdmasterfingerprint, :string
    field :labels, {:array, :string}, default: []
  end

  @required_fields ~w(address script_pub_key ismine iswatchonly solvable isscript
                      ischange iswitness)a
  @optional_fields ~w(desc witness_version witness_program script hex pubkeys
                      sigsrequired pubkey embedded iscompressed timestamp
                      hdkeypath hdseedid hdmasterfingerprint labels)a

  # Valid script types
  @valid_script_types ~w(nonstandard pubkey pubkeyhash scripthash multisig nulldata
                         witness_v0_keyhash witness_v0_scripthash witness_unknown)

  ## API

  @doc """
  Creates a new `GetAddressInfoResult` schema.
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    # Convert keys from string to atom and handle field name mapping
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action(:getaddressinfo_result)
  end

  @doc """
  Creates a new `GetAddressInfoResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(attrs) when is_map(attrs) do
    # Convert keys from string to atom and handle field name mapping
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action!(:getaddressinfo_result)
  end

  @doc """
  Creates a changeset for the `GetAddressInfoResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(normalize_attrs(attrs), @required_fields ++ @optional_fields, empty_values: [])
    |> validate_required(@required_fields)
    |> validate_inclusion(:script, @valid_script_types)
  end
end
