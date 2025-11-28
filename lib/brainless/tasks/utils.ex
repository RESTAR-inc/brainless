defmodule Brainless.Tasks.Utils do
  @moduledoc """
  Seed Utils
  """
  require Logger

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

  defp get_or_create_genre(name) do
    case MediaLibrary.get_genre_by_name(name) do
      %Genre{} = genre ->
        genre

      nil ->
        case MediaLibrary.create_genre(%{name: name}) do
          {:ok, %Genre{} = new_genre} ->
            Logger.info("Genre:created #{new_genre.id}/#{new_genre.name}")
            new_genre

          {:error, _} ->
            Logger.error("Genre:error #{name}")
            raise "Genre Import Error"
        end
    end
  end

  defp create_person("", _), do: nil

  defp create_person(name, occupation) when is_binary(name) do
    case MediaLibrary.create_person(%{name: name, occupations: [occupation]}) do
      {:ok, %Person{} = new_person} ->
        Logger.info("Person:created #{new_person.id}/#{new_person.name}")
        new_person

      {:error, _} ->
        raise "Person:create #{name}"
    end
  end

  defp update_person(%Person{} = person, occupation) do
    attrs = %{occupations: [occupation | person.occupations]}

    case MediaLibrary.update_person(person, attrs) do
      {:ok, %Person{} = updated_person} ->
        Logger.info("Person:updated #{updated_person.id}/#{updated_person.name}")
        updated_person

      {:error, _} ->
        raise "Person:update #{person.name}"
    end
  end

  def get_or_create_person(name, occupation) do
    case MediaLibrary.get_person_by_name(name) do
      %Person{} = person ->
        if occupation in person.occupations do
          person
        else
          update_person(person, occupation)
        end

      nil ->
        create_person(name, occupation)
    end
  end

  def create_genres(""), do: []
  def create_genres(nil), do: []

  def create_genres(input) when is_binary(input) do
    input
    |> String.split(",")
    |> Enum.map(&String.trim(&1))
    |> Enum.uniq()
    |> Enum.map(&get_or_create_genre/1)
  end
end
