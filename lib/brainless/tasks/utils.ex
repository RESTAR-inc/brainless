defmodule Brainless.Tasks.Utils do
  @moduledoc """
  Seed Utils
  """

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

  def parse_float(input) do
    case Float.parse(input) do
      {value, _} -> value
      :error -> nil
    end
  end

  def parse_int(input) do
    case Integer.parse(input) do
      {value, _} -> value
      :error -> nil
    end
  end

  def get_or_create_person(name, occupation) do
    case MediaLibrary.get_person_by_name(name) do
      %Person{} = person ->
        if occupation in person.occupations do
          {:ok, person}
        else
          MediaLibrary.update_person(person, %{occupations: [occupation | person.occupations]})
        end

      nil ->
        MediaLibrary.create_person(%{name: name, occupations: [occupation]})
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

  def create_persons_from_str(input, occupation, delimiter \\ ",") when is_binary(input) do
    created =
      input
      |> String.split(delimiter)
      |> Enum.map(&String.trim(&1))
      |> Enum.uniq()
      |> Enum.reject(&(String.length(&1) == 0))
      |> Enum.map(&get_or_create_person(&1, occupation))

    case Enum.find(created, &match?({:error, _}, &1)) do
      nil ->
        {:ok, Enum.map(created, fn {_, person} -> person end)}

      {:error, error} ->
        {:error, error}
    end
  end
end
