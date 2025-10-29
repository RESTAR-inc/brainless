defmodule BrainlessWeb.MovieLiveTest do
  use BrainlessWeb.ConnCase

  import Phoenix.LiveViewTest
  import Brainless.MediaLibraryFixtures

  @create_attrs %{description: "some description", title: "some title", poster_url: "some poster_url", genre: "some genre", director: "some director", release_date: "2025-10-28", imdb_rating: 120.5, meta_score: 42}
  @update_attrs %{description: "some updated description", title: "some updated title", poster_url: "some updated poster_url", genre: "some updated genre", director: "some updated director", release_date: "2025-10-29", imdb_rating: 456.7, meta_score: 43}
  @invalid_attrs %{description: nil, title: nil, poster_url: nil, genre: nil, director: nil, release_date: nil, imdb_rating: nil, meta_score: nil}
  defp create_movie(_) do
    movie = movie_fixture()

    %{movie: movie}
  end

  describe "Index" do
    setup [:create_movie]

    test "lists all movies", %{conn: conn, movie: movie} do
      {:ok, _index_live, html} = live(conn, ~p"/movies")

      assert html =~ "Listing Movies"
      assert html =~ movie.title
    end

    test "saves new movie", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/movies")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Movie")
               |> render_click()
               |> follow_redirect(conn, ~p"/movies/new")

      assert render(form_live) =~ "New Movie"

      assert form_live
             |> form("#movie-form", movie: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#movie-form", movie: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/movies")

      html = render(index_live)
      assert html =~ "Movie created successfully"
      assert html =~ "some title"
    end

    test "updates movie in listing", %{conn: conn, movie: movie} do
      {:ok, index_live, _html} = live(conn, ~p"/movies")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#movies-#{movie.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/movies/#{movie}/edit")

      assert render(form_live) =~ "Edit Movie"

      assert form_live
             |> form("#movie-form", movie: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#movie-form", movie: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/movies")

      html = render(index_live)
      assert html =~ "Movie updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes movie in listing", %{conn: conn, movie: movie} do
      {:ok, index_live, _html} = live(conn, ~p"/movies")

      assert index_live |> element("#movies-#{movie.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#movies-#{movie.id}")
    end
  end

  describe "Show" do
    setup [:create_movie]

    test "displays movie", %{conn: conn, movie: movie} do
      {:ok, _show_live, html} = live(conn, ~p"/movies/#{movie}")

      assert html =~ "Show Movie"
      assert html =~ movie.title
    end

    test "updates movie and returns to show", %{conn: conn, movie: movie} do
      {:ok, show_live, _html} = live(conn, ~p"/movies/#{movie}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/movies/#{movie}/edit?return_to=show")

      assert render(form_live) =~ "Edit Movie"

      assert form_live
             |> form("#movie-form", movie: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#movie-form", movie: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/movies/#{movie}")

      html = render(show_live)
      assert html =~ "Movie updated successfully"
      assert html =~ "some updated title"
    end
  end
end
