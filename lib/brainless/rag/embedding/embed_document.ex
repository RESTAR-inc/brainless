defmodule Brainless.Rag.Embedding.EmbedDocument do
  @moduledoc """
  Document
  """
  @derive JSON.Encoder

  @type t :: %__MODULE__{
          meta: map(),
          content: String.t()
        }
  @enforce_keys [:meta, :content]
  defstruct [:meta, :content]
end
