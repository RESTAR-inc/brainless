defmodule BrainlessWeb.ErrorJSONTest do
  use BrainlessWeb.ConnCase, async: true

  test "renders 404" do
    assert BrainlessWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert BrainlessWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
