defmodule Brainless.Rag.Embedding.Meta do
  @moduledoc """
  TODO
  """
  @derive JSON.Encoder

  @type t :: %__MODULE__{
          id: pos_integer(),
          type: String.t(),
          data: map()
        }
  @enforce_keys [:id, :type, :data]
  defstruct [:id, :type, :data]

  def index_mappings(mappings) do
    %{
      id: %{type: "integer"},
      type: %{type: "text"},
      data: %{
        properties: mappings
      }
    }
  end

  @spec from_source(map(), fun()) :: t()
  def from_source(%{"id" => id, "type" => type, "data" => data}, extract) do
    %__MODULE__{
      id: id,
      type: type,
      data: extract.(data)
    }
  end
end
