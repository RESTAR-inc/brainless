defmodule Brainless.Rag.Generation do
  @model_repo {:hf, "mistralai/Mistral-7B-Instruct-v0.2"}

  def serving do
    {:ok, model_info} = Bumblebee.load_model(@model_repo, type: :bf16, backend: EXLA.Backend)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(@model_repo)
    {:ok, generation_config} = Bumblebee.load_generation_config(@model_repo)

    Bumblebee.Text.generation(model_info, tokenizer, generation_config,
      compile: [batch_size: 1, sequence_length: 1028],
      stream: true,
      defn_options: [compiler: EXLA]
    )
  end

  def predict(:bumblebee, prompt) do
    Nx.Serving.batched_run(__MODULE__, prompt)
  end

  def predict(:gemini, _prompt) do
    nil
  end
end
