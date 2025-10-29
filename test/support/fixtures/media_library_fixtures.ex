defmodule Brainless.MediaLibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Brainless.MediaLibrary` context.
  """

  @doc """
  Generate a movie.
  """
  def movie_fixture(attrs \\ %{}) do
    {:ok, movie} =
      attrs
      |> Enum.into(%{
        description: "some description",
        director: "some director",
        genre: "some genre",
        imdb_rating: 120.5,
        meta_score: 42,
        poster_url: "some poster_url",
        release_date: ~D[2025-10-28],
        title: "some title"
      })
      |> Brainless.MediaLibrary.create_movie()

    movie
  end
end
