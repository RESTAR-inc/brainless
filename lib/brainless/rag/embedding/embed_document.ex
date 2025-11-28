defmodule Brainless.Rag.Embedding.EmbedDocument do
  @moduledoc """
  Document
  """
  @derive JSON.Encoder

  @type t :: %__MODULE__{
          id: String.t(),
          meta: map(),
          content: String.t()
        }
  @enforce_keys [:id, :meta, :content]
  defstruct [:id, :meta, :content]
end
