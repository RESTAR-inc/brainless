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

  @spec from_source(String.t(), map(), fun()) :: t()
  def from_source(id, %{"meta" => raw_meta, "content" => content}, extract_meta) do
    %__MODULE__{
      id: id,
      content: content,
      meta: Meta.from_source(raw_meta, extract_meta)
    }
  end
end
