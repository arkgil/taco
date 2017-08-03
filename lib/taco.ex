defmodule Taco do
  @moduledoc """
  Composition and error handling of sequential computations,
  similar to `Ecto.Multi`
  """

  defstruct actions: %{}, order: []

  @typep actions :: %{tag => action}
  @typep order :: [tag]

  @opaque t :: %__MODULE__{actions: actions, order: order}
  @type tag :: atom
  @type result :: term
  @type error :: term
  @type results :: %{tag => result}
  @type action :: (results_so_far :: results -> action_ret)
  @type action_ret :: {:ok, result} | {:halt, result} | {:error, error}

  @spec new :: t
  def new, do: %__MODULE__{}

  @spec then(t, tag, action) :: t
  def then(%__MODULE__{actions: actions, order: order} = taco, tag, action)
    when is_function(action, 1) and is_atom(tag) do
    case Map.has_key?(actions, tag) do
      false ->
        actions = Map.put(actions, tag, action)
        order = [tag | order]
        %__MODULE__{taco | actions: actions, order: order}
      true ->
        raise ArgumentError, "duplicate action tag"
    end
  end
  def then(%__MODULE__{}, tag, _) when not is_atom(tag) do
    raise ArgumentError, "action tag must be an atom"
  end
  def then(%__MODULE__{}, _, _) do
    raise ArgumentError, "action must be a 1-arity function"
  end

  @spec run(t) :: {:ok, tag, result}
                | {:error, tag, error, results_so_far :: results}
  def run(taco) do
    order = Enum.reverse(taco.order)
    run_actions(taco.actions, order, %{})
  end

  @spec run_actions(actions, order, results)
    :: {:ok, tag, result} | {:error, tag, error, results}
  defp run_actions(_, [], _) do
    raise ArgumentError, "taco passed to run/1 has no actions"
  end
  defp run_actions(actions, [tag | _] = order, results) do
    action = Map.fetch!(actions, tag)
    case action.(results) do
      {:error, error} ->
        {:error, tag, error, results}
      {:halt, result} ->
        {:ok, tag, result}
      {:ok, result} ->
        results = Map.put(results, tag, result)
        maybe_continue(actions, order, results)
    end
  end

  @spec maybe_continue(actions, order, results)
    :: {:ok, tag, result} | {:error, tag, error, results}
  defp maybe_continue(_, [last_tag], results) do
    result = Map.fetch!(results, last_tag)
    {:ok, last_tag, result}
  end
  defp maybe_continue(actions, [_ | order], results) do
    run_actions(actions, order, results)
  end
end
