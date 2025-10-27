defmodule BrainlessWeb.PageController do
  use BrainlessWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
