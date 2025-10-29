defmodule Brainless.MediaLibraryTest do
  use Brainless.DataCase

  alias Brainless.MediaLibrary

  describe "movies" do
    alias Brainless.MediaLibrary.Movie

    import Brainless.MediaLibraryFixtures

    @invalid_attrs %{description: nil, title: nil, poster_url: nil, genre: nil, director: nil, release_date: nil, imdb_rating: nil, meta_score: nil}

    test "list_movies/0 returns all movies" do
      movie = movie_fixture()
      assert MediaLibrary.list_movies() == [movie]
    end

    test "get_movie!/1 returns the movie with given id" do
      movie = movie_fixture()
      assert MediaLibrary.get_movie!(movie.id) == movie
    end

    test "create_movie/1 with valid data creates a movie" do
      valid_attrs = %{description: "some description", title: "some title", poster_url: "some poster_url", genre: "some genre", director: "some director", release_date: ~D[2025-10-28], imdb_rating: 120.5, meta_score: 42}

      assert {:ok, %Movie{} = movie} = MediaLibrary.create_movie(valid_attrs)
      assert movie.description == "some description"
      assert movie.title == "some title"
      assert movie.poster_url == "some poster_url"
      assert movie.genre == "some genre"
      assert movie.director == "some director"
      assert movie.release_date == ~D[2025-10-28]
      assert movie.imdb_rating == 120.5
      assert movie.meta_score == 42
    end

    test "create_movie/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = MediaLibrary.create_movie(@invalid_attrs)
    end

    test "update_movie/2 with valid data updates the movie" do
      movie = movie_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title", poster_url: "some updated poster_url", genre: "some updated genre", director: "some updated director", release_date: ~D[2025-10-29], imdb_rating: 456.7, meta_score: 43}

      assert {:ok, %Movie{} = movie} = MediaLibrary.update_movie(movie, update_attrs)
      assert movie.description == "some updated description"
      assert movie.title == "some updated title"
      assert movie.poster_url == "some updated poster_url"
      assert movie.genre == "some updated genre"
      assert movie.director == "some updated director"
      assert movie.release_date == ~D[2025-10-29]
      assert movie.imdb_rating == 456.7
      assert movie.meta_score == 43
    end

    test "update_movie/2 with invalid data returns error changeset" do
      movie = movie_fixture()
      assert {:error, %Ecto.Changeset{}} = MediaLibrary.update_movie(movie, @invalid_attrs)
      assert movie == MediaLibrary.get_movie!(movie.id)
    end

    test "delete_movie/1 deletes the movie" do
      movie = movie_fixture()
      assert {:ok, %Movie{}} = MediaLibrary.delete_movie(movie)
      assert_raise Ecto.NoResultsError, fn -> MediaLibrary.get_movie!(movie.id) end
    end

    test "change_movie/1 returns a movie changeset" do
      movie = movie_fixture()
      assert %Ecto.Changeset{} = MediaLibrary.change_movie(movie)
    end
  end
end
