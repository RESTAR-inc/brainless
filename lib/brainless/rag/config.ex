defmodule Brainless.Rag.Config do
  @moduledoc """
  Provides configuration helpers for RAG components.
  """

  defmacro __using__(_opts) do
    quote do
      def get_rag_config(key) do
        :brainless
        |> Application.fetch_env!(Brainless.Rag)
        |> Keyword.fetch!(key)
      end

      # def provider, do: get_rag_settings(:embedding_provider)
      # def dimensions, do: get_rag_settings(:embedding_dimensions)
    end
  end
end
