defmodule Brainless.Rag.Embedding.EmbedData do
  @moduledoc """
  Document
  """
  @derive JSON.Encoder

  @type t :: %__MODULE__{
          id: String.t(),
          meta: map(),
          embedding: [float()]
        }
  @enforce_keys [:id, :meta, :embedding]
  defstruct [:id, :meta, :embedding]
end
