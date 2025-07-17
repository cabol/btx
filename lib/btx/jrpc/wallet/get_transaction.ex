defmodule BTx.JRPC.Wallet.GetTransaction do
  @moduledoc """
  Get detailed information about in-wallet transaction `txid`.
  """

  use Ecto.Schema

  import BTx.JRPC.Helpers
  import Ecto.Changeset

  ## Types & Schema

  @typedoc "GetTransaction request"
  @type t() :: %__MODULE__{
          txid: String.t() | nil,
          include_watchonly: boolean(),
          verbose: boolean()
        }

  @primary_key false
  embedded_schema do
    field :txid, :string
    field :include_watchonly, :boolean, default: true
    field :verbose, :boolean, default: false
  end

  @required_fields ~w(txid)a
  @optional_fields ~w(include_watchonly verbose)a

  ## Encodable protocol

  defimpl BTx.JRPC.Encodable, for: __MODULE__ do
    def encode(%{
          txid: txid,
          include_watchonly: include_watchonly,
          verbose: verbose
        }) do
      Map.merge(common_params(), %{
        method: "gettransaction",
        params: [txid, include_watchonly, verbose]
      })
    end
  end

  ## API

  @doc """
  Creates a new `GetTransaction` request.
  """
  @spec new(keyword() | map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action(:gettransaction)
  end

  @doc """
  Creates a new `GetTransaction` request.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(attrs) do
    %__MODULE__{}
    |> changeset(Enum.into(attrs, %{}))
    |> apply_action!(:gettransaction)
  end

  @doc """
  Creates a changeset for the `GetTransaction` request.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(t, attrs) do
    t
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:txid, is: 64)
  end
end
