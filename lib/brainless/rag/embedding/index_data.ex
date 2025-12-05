defmodule Brainless.Rag.Embedding.IndexData do
  @moduledoc """
  TODO
  """
  alias Brainless.Rag.Embedding.Meta

  @derive JSON.Encoder

  @type t :: %__MODULE__{
          id: String.t(),
          content: String.t(),
          meta: Meta.t()
        }
  @enforce_keys [:id, :content, :meta]
  defstruct [:id, :content, :meta]
end
