defmodule Brainless.Rag.Response do
  @moduledoc """
  Struct representing a RAG search response
  """
  alias Brainless.Rag.Result

  @derive JSON.Encoder

  @type t :: %__MODULE__{
          query: String.t(),
          ai_response: String.t() | nil,
          results: [Result.t()]
        }

  @enforce_keys [:query, :ai_response, :results]
  defstruct [:query, :ai_response, :results]
end
