defmodule Brainless.Tasks.Utils do
  @moduledoc """
  Seed Utils
  """

  alias Brainless.CsvParser
  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Genre
  alias Brainless.MediaLibrary.Person

  def parse_year(nil), do: nil

  def parse_year(year) do
    case Integer.parse(year) do
      {value, _} -> Date.new!(value, 1, 1)
      :error -> nil
    end
  end

  def parse_float(nil), do: nil

  def parse_float(input) do
    case Float.parse(input) do
      {value, _} -> value
      :error -> nil
    end
  end

  def parse_int(nil), do: nil

  def parse_int(input) do
    case Integer.parse(input) do
      {value, _} -> value
      :error -> nil
    end
  end

  def get_or_create_person(name) do
    case MediaLibrary.get_person_by_name(name) do
      %Person{} = person ->
        {:ok, person}

      nil ->
        MediaLibrary.create_person(%{name: name})
    end
  end

  def get_or_create_genre(name) do
    case MediaLibrary.get_genre_by_name(name) do
      %Genre{} = genre ->
        {:ok, genre}

      nil ->
        MediaLibrary.create_genre(%{name: name})
    end
  end

  def create_genres_from_str(input, delimiter \\ ",") when is_binary(input) do
    created =
      input
      |> String.split(delimiter)
      |> Enum.map(&String.trim(&1))
      |> Enum.uniq()
      |> Enum.reject(&(String.length(&1) == 0))
      |> Enum.map(&get_or_create_genre/1)

    case Enum.find(created, &match?({:error, _}, &1)) do
      nil ->
        {:ok, Enum.map(created, fn {_, genre} -> genre end)}

      {:error, error} ->
        {:error, error}
    end
  end

  def create_persons_from_str("[" <> input) do
    input
    |> String.slice(0..-2//1)
    |> String.split(",")
    |> Enum.map(fn name ->
      name
      |> String.trim()
      |> String.slice(1..-2//1)
    end)
    |> Enum.reject(&(String.length(&1) == 0))
    |> Enum.uniq()
    |> Enum.map(&get_or_create_person/1)
    |> assert_is_list_is_invalid()
  end

  def create_persons_from_str(input, delimiter) when is_binary(input) do
    input
    |> String.split(delimiter)
    |> Enum.map(&String.trim(&1))
    |> Enum.reject(&(String.length(&1) == 0))
    |> Enum.uniq()
    |> Enum.map(&get_or_create_person/1)
    |> assert_is_list_is_invalid()
  end

  @spec seed(String.t(), fun()) :: map()
  def seed(file_name, func) do
    File.stream!(file_name)
    |> CsvParser.parse_stream()
    |> Stream.map(fn row ->
      case func.(row) do
        :ok -> :ok
        :error -> :error
        :skip -> :skip
        _ -> raise "Invalid import result"
      end
    end)
    |> Enum.reduce(%{}, fn key, stats ->
      Map.update(stats, key, 1, &(&1 + 1))
    end)
  end

  defp assert_is_list_is_invalid(items) do
    case Enum.find(items, &match?({:error, _}, &1)) do
      nil ->
        {:ok, Enum.map(items, fn {_, item} -> item end)}

      {:error, error} ->
        {:error, error}
    end
  end
end
