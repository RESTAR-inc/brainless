defmodule Brainless.Rag.Embedding.Provider.Local do
  @moduledoc """
  Local embeddings
  """
  use Brainless.Rag.Embedding.Provider

  alias Brainless.Rag.Embedding.EmbedData

  @impl true
  def str_to_vector(input, _opts \\ []) do
    case Req.post(get_url(:one), headers: get_headers(), json: %{content: input, meta: %{}}) do
      {:ok, %Req.Response{body: body}} ->
        {:ok, map_response_item(body)}

      {:error, _reason} ->
        {:error, "Unable to create a vector"}
    end
  end

  @impl true
  def docs_to_index_list(documents, _opts \\ []) do
    json = Enum.map(documents, &%{meta: &1.meta, content: &1.content})

    case Req.post(get_url(:many), headers: get_headers(), json: json) do
      {:ok, %Req.Response{body: body}} ->
        {:ok, Enum.map(body, &map_response_item/1)}

      {:error, _reason} ->
        {:error, "Unable to create a vector list"}
    end
  end

  defp map_response_item(%{"embedding" => embedding, "meta" => meta}) do
    %EmbedData{meta: meta, embedding: embedding}
  end

  defp get_url(:many), do: "#{get_service_url()}/api/embeddings/many"
  defp get_url(:one), do: "#{get_service_url()}/api/embeddings/one"

  defp get_service_url do
    Keyword.fetch!(Application.fetch_env!(:brainless, Brainless.Rag.Embedding), :service_url)
  end

  defp get_api_key do
    Keyword.fetch!(Application.fetch_env!(:brainless, Brainless.Rag.Embedding), :api_key)
  end

  defp get_headers do
    ["x-api-key": get_api_key()]
  end
end
