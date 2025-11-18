defmodule Brainless.Rag.Generation.Provider.Local do
  @moduledoc """
  List of supported models
    - mistralai/Mistral-7B-Instruct-v0.2
  """

  use Brainless.Rag.Generation.Provider
  require Logger

  def serving do
    model = model_repo()
    {:ok, model_info} = Bumblebee.load_model(model)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(model)
    {:ok, generation_config} = Bumblebee.load_generation_config(model)

    Logger.info("Starting Bumblebee generator...")

    Bumblebee.Text.generation(model_info, tokenizer, generation_config,
      compile: [batch_size: 1, sequence_length: 1028],
      defn_options: [compiler: EXLA]
    )
  end

  @impl true
  def predict(_input) do
    # TODO: implement me
    # case Nx.Serving.batched_run(__MODULE__, input) do
    #   %{results: results} ->
    #     dbg({"Brainless.Rag.Generation.Bumblebee", results})
    #     {:ok, []}

    #   reason ->
    #     {:error, reason}
    # end

    {:ok, []}
  end

  defp model_repo do
    # hf_token = Keyword.fetch!(Application.fetch_env!(:brainless, Brainless.Rag), :hf_token)
    # model_repo = {:hf, "meta-llama/Llama-3.2-1B", [auth_token: hf_token]}
    {:hf, "mistralai/Mistral-7B-Instruct-v0.2"}
  end
end
