defmodule Brainless.Rag.Embedding.EmbedData do
  @moduledoc """
  Document
  """
  @derive JSON.Encoder

  @type t :: %__MODULE__{
          meta: map(),
          embedding: list(float())
        }
  @enforce_keys [:meta, :embedding]
  defstruct [:meta, :embedding]
end
