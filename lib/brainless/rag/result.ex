defmodule Brainless.Rag.Result do
  @type t :: %__MODULE__{
          type: String.t(),
          data: term(),
          score: float()
        }
  @enforce_keys [:type, :data, :score]
  defstruct [:type, :data, :score]
end
