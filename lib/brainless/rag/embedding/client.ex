defmodule Brainless.Rag.Embedding.Client do
  @moduledoc """
  See https://www.elastic.co/docs/solutions/search/vector/knn
  """
  use HTTPoison.Base

  alias Brainless.Rag.Embedding.EmbedData

  @type search_options ::
          {:k, pos_integer()}
          | {:similarity, float()}
          | {:num_candidates, pos_integer()}
          | {:filter, map()}

  # l2_norm, cosine, dot_product, max_inner_product

  @similarity "cosine"
  @default_timeout to_timeout(second: 30)
  @search_size 30
  @search_k 100
  @search_similarity 0.3
  @search_num_candidates 1000

  @impl true
  def process_request_options(options) do
    options
    |> Keyword.put_new(:timeout, @default_timeout)
    |> Keyword.put_new(:recv_timeout, @default_timeout)
    |> Keyword.put_new(:hackney, pool: false)
  end

  @impl true
  def process_request_headers(headers) do
    key = "Content-Type"
    List.keystore(headers, key, 0, {key, "application/json; charset=UTF-8"})
  end

  @impl true
  def process_request_url(url) do
    :brainless
    |> Application.fetch_env!(Brainless.Rag.Embedding)
    |> Keyword.fetch!(:es_url)
    |> URI.merge(url)
    |> URI.to_string()
  end

  @impl true
  def process_request_body(body) when is_binary(body), do: body
  def process_request_body(body), do: body |> JSON.encode!()

  @impl true
  def process_response_body(body) do
    case JSON.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _} -> body
    end
  end

  defp get_mappings(dimensions, meta) do
    %{
      properties: %{
        embedding: %{
          type: "dense_vector",
          dims: dimensions,
          index: true,
          similarity: @similarity
        },
        meta: %{
          properties: meta
        }
      }
    }
  end

  @spec create_index(String.t(), integer(), map()) :: {:error, term()} | :ok
  def create_index(index_name, dimensions, mappings) do
    case put!(index_name, %{mappings: get_mappings(dimensions, mappings)}) do
      %{body: %{"error" => error}} ->
        {:error, error}

      _ ->
        :ok
    end
  end

  @spec insert_index(String.t(), EmbedData.t()) :: {:error, term()} | :ok
  def insert_index(index_name, %EmbedData{id: id, meta: meta, embedding: embedding}) do
    payload = %{meta: meta, embedding: embedding}

    case put!("#{index_name}/_doc/#{id}/", payload) do
      %{body: %{"error" => error}} ->
        {:error, error}

      _ ->
        :ok
    end
  end

  @spec delete_index(String.t()) :: any()
  def delete_index(index_name) do
    case delete!(index_name) do
      %{body: %{"error" => error}} ->
        {:error, error}

      _ ->
        :ok
    end
  end

  defp apply_filter(base_params, filter) when is_map(filter) do
    Map.put_new(base_params, :filter, filter)
  end

  defp apply_filter(base_params, nil), do: base_params

  defp prepare_search_params(vector, opts) do
    knn =
      %{
        query_vector: vector,
        field: "embedding",
        similarity: Keyword.get(opts, :similarity, @search_similarity),
        k: Keyword.get(opts, :k, @search_k),
        num_candidates: Keyword.get(opts, :num_candidates, @search_num_candidates)
      }
      |> apply_filter(Keyword.get(opts, :filter))

    %{
      knn: knn,
      size: Keyword.get(opts, :size, @search_size)
    }
  end

  defp extract_search_item(%{"_source" => %{"meta" => meta}, "_score" => score}),
    do: {meta, invert_score(score, @similarity)}

  @spec search(String.t(), [float()], [search_options()]) ::
          {:error, term()} | {:ok, [{map(), float()}]}
  @spec search(binary(), [float()]) :: {:error, <<_::104>>} | {:ok, [{map(), float()}]}
  def search(index_name, vector, opts \\ []) do
    url = "#{index_name}/_search"

    params = prepare_search_params(vector, opts)

    case post!(url, params) do
      %{status_code: 200, body: %{"hits" => %{"hits" => hits}}} ->
        {:ok, Enum.map(hits, &extract_search_item/1)}

      _ ->
        {:error, "Unknown error"}
    end
  end

  # See https://www.elastic.co/docs/solutions/search/vector/knn#knn-similarity-search
  # How to invert _score back to the underlying similarity
  #   l2_norm: sqrt((1 / _score) - 1)
  #   cosine: (2 * _score) - 1
  #   dot_product: (2 * _score) - 1
  #   max_inner_product:
  #     _score < 1: 1 - (1 / _score)
  #     _score >= 1: _score - 1
  def invert_score(score, "l2_norm"), do: :math.sqrt(1 / score - 1)
  def invert_score(score, "cosine"), do: 2 * score - 1
  def invert_score(score, "dot_product"), do: 2 * score - 1
  def invert_score(score, "max_inner_product") when score < 1, do: 1 - 1 / score
  def invert_score(score, "max_inner_product") when score >= 1, do: score - 1
  def invert_score(_, _), do: raise("Invalid type")
end
