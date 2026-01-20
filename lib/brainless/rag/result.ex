defmodule Brainless.Rag.Result do
  @moduledoc """
  Struct representing a RAG result item
  """
  @type t :: %__MODULE__{
          type: String.t(),
          data: term(),
          score: float()
        }
  @enforce_keys [:type, :data, :score]
  defstruct [:type, :data, :score]
end
