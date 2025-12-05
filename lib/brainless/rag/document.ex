defmodule Brainless.Rag.Document do
  @moduledoc """
  Embed Document
  """
  alias Brainless.Rag.Embedding.IndexData

  @callback index_name() :: String.t()
  @callback get_index_data(struct()) :: IndexData.t() | nil
  @callback get_meta_data_mappings() :: map() | nil
  @callback get_meta_data(struct()) :: map()
  @callback format(struct()) :: Strint.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Brainless.Rag.Document
    end
  end
end
