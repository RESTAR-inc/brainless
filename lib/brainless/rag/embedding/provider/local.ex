defmodule Brainless.Rag.Embedding.Provider.Local do
  @moduledoc """
  Local embeddings
  """
  use Brainless.Rag.Config
  use Brainless.Rag.Embedding.Provider

  alias Brainless.Rag.Embedding.IndexData

  @impl true
  def to_vector(input) do
    json = %{
      content: input,
      dimensions: get_rag_config(:embedding_dimensions)
    }

    case Req.post(endpoint(:one), headers: headers(), json: json) do
      {:ok, %Req.Response{body: body}} ->
        {:ok, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def to_index_list(data_list) do
    json = %{
      documents: Enum.map(data_list, &%{id: &1.id, content: &1.content}),
      dimensions: get_rag_config(:embedding_dimensions)
    }

    case Req.post(endpoint(:bulk), headers: headers(), json: json) do
      {:ok, %Req.Response{status: 200, body: embeds}} ->
        result =
          [data_list, embeds]
          |> Enum.zip_with(&zip_embeds/1)
          |> Enum.reject(&is_nil/1)

        {:ok, result}

      {:ok, %Req.Response{status: 422}} ->
        {:error, :embedding_validation_error}

      {:error, _} ->
        {:error, :embedding_error}
    end
  end

  defp zip_embeds([%IndexData{id: id} = input, %{"id" => id, "vector" => vector}]),
    do: {input, vector}

  defp zip_embeds(_), do: nil

  defp endpoint(:one), do: "#{get_rag_config(:service_url)}/api/embeddings"
  defp endpoint(:bulk), do: "#{get_rag_config(:service_url)}/api/embeddings/bulk"

  defp headers do
    [
      "x-api-key": get_rag_config(:service_api_key),
      "content-type": ["application/json"]
    ]
  end
end
