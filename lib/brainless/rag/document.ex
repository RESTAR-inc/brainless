defmodule Brainless.Rag.Document do
  @moduledoc """
  Embed Document
  """
  alias Brainless.Rag.Embedding.IndexData
  alias Brainless.Rag.Result

  @callback index_name() :: String.t()
  @callback get_index_data(struct()) :: IndexData.t() | nil
  @callback get_meta_data_mappings() :: map() | nil
  @callback get_meta_data(struct()) :: map()
  @callback format(struct()) :: String.t()
  @callback extract_data(map()) :: map()
  @callback retrieve([{IndexData.t(), float()}]) :: [Result.t()]

  defmacro __using__(_opts) do
    quote do
      @behaviour Brainless.Rag.Document

      @impl Brainless.Rag.Document
      def extract_data(data), do: data

      defoverridable extract_data: 1
    end
  end
end
