defmodule BTx.RPC.Wallets.SendToAddressResult do
  @moduledoc """
  Result from the `sendtoaddress` JSON RPC API.

  The result can be either a simple string (transaction ID) when verbose is
  `false`, or a JSON object with additional details when verbose is `true`.
  """

  use Ecto.Schema

  import BTx.Ecto.ChangesetUtils
  import Ecto.Changeset

  alias BTx.RPC.Response

  ## Types & Schema

  @typedoc "SendToAddressResult"
  @type t() :: %__MODULE__{
          txid: String.t() | nil,
          fee_reason: String.t() | nil
        }

  @derive BTx.json_encoder()
  @primary_key false
  embedded_schema do
    field :txid, :string
    field :fee_reason, :string
  end

  @required_fields ~w(txid)a
  @optional_fields ~w(fee_reason)a

  ## API

  @doc """
  Creates a new `SendToAddressResult` schema.

  Handles both string responses (when verbose=false) and object responses (when verbose=true).
  """
  @spec new(Response.result()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(result)

  # Handle string response (verbose=false) - just the transaction ID
  def new(txid) when is_binary(txid) do
    %__MODULE__{}
    |> changeset(%{txid: txid})
    |> apply_action(:sendtoaddress_result)
  end

  # Handle object response (verbose=true) - contains txid and fee_reason
  def new(attrs) when is_map(attrs) do
    # Convert keys from string to atom
    normalized_attrs = normalize_attrs(attrs)

    %__MODULE__{}
    |> changeset(normalized_attrs)
    |> apply_action(:sendtoaddress_result)
  end

  @doc """
  Creates a new `SendToAddressResult` schema.
  """
  @spec new!(Response.result()) :: t()
  def new!(result) do
    case new(result) do
      {:ok, data} ->
        data

      {:error, changeset} ->
        raise Ecto.InvalidChangesetError, action: :sendtoaddress_result, changeset: changeset
    end
  end

  @doc """
  Creates a changeset for the `SendToAddressResult` schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:txid, is: 64)
    |> validate_format(:txid, ~r/^[a-fA-F0-9]{64}$/)
  end
end
