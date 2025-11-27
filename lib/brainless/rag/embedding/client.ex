defmodule Brainless.Rag.Embedding.Client do
  @moduledoc """
  See https://www.elastic.co/docs/solutions/search/vector/knn#knn-similarity-search

  How similarity works:

    l2_norm: sqrt((1 / _score) - 1)
    cosine: (2 * _score) - 1
    dot_product: (2 * _score) - 1
    max_inner_product:
      _score < 1: 1 - (1 / _score)
      _score >= 1: _score - 1
  """
  use HTTPoison.Base

  alias Brainless.Rag.Embedding.EmbedData

  @type search_options ::
          {:k, pos_integer()}
          | {:similarity, float()}
          | {:num_candidates, pos_integer()}
          | {:filter, map()}

  @similarity "cosine"
  @default_timeout to_timeout(second: 30)
  @search_k 20
  @search_similarity 0.5
  @search_num_candidates 50

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
    |> Keyword.fetch!(:elasticsearch_url)
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

  @spec get_mappings(integer(), map()) :: map()
  def get_mappings(dimensions, meta) do
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

  @spec delete_index(String.t()) :: any()
  def delete_index(index_name) do
    case delete!(index_name) do
      %{body: %{"error" => error}} ->
        {:error, error}

      _ ->
        :ok
    end
  end

  @spec create_index(String.t(), integer(), map()) :: any()
  def create_index(index_name, dimensions, mappings) do
    case put!(index_name, %{mappings: get_mappings(dimensions, mappings)}) do
      %{body: %{"error" => error}} ->
        {:error, error}

      _ ->
        :ok
    end
  end

  @spec insert_index(String.t(), String.t(), EmbedData.t()) :: any()
  def insert_index(index_name, id, %EmbedData{meta: meta, embedding: embedding}) do
    payload = %{meta: meta, embedding: embedding}

    case put!("#{index_name}/_doc/#{id}/", payload) do
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
    filter = Keyword.get(opts, :filter)

    %{
      query_vector: vector,
      field: "embedding",
      similarity: Keyword.get(opts, :similarity, @search_similarity),
      k: Keyword.get(opts, :k, @search_k),
      num_candidates: Keyword.get(opts, :num_candidates, @search_num_candidates)
    }
    |> apply_filter(filter)
  end

  defp extract_search_item(%{"_source" => %{"meta" => meta}, "_score" => score}),
    do: {meta, score}

  @spec search(String.t(), [float()], [search_options()]) ::
          {:error, term()} | {:ok, [{map(), float()}]}
  def search(index_name, vector, opts \\ []) do
    url = "#{index_name}/_search"
    params = %{knn: prepare_search_params(vector, opts)}

    case post!(url, params) do
      %{status_code: 200, body: %{"hits" => %{"hits" => hits}}} ->
        {:ok, Enum.map(hits, &extract_search_item/1)}

      _ ->
        {:error, "Unknown error"}
    end
  end
end
