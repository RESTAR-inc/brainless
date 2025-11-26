defmodule Brainless.Rag.Document do
  alias Brainless.Rag.Embedding.EmbedDocument

  @callback format(struct()) :: String.t()
  @callback mappings() :: map()
  @callback index_name() :: String.t()
  @callback document(struct()) :: EmbedDocument.t()
  @callback get_id(struct()) :: String.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Brainless.Rag.Document
    end
  end
end
