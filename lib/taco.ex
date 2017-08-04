defmodule Taco do
  @moduledoc """
  Composition and error handling of sequential computations, similar to
  `Ecto.Multi`

  Taco allows to create a chain of actions which might either succeed,
  fail, or halt the execution of further actions in the pipeline.

  Let's start with an example!

      number = 2

      Taco.new()
      |> Taco.then(:add, fn _ -> {:ok, number + 3} end)
      |> Taco.then(:multiply, fn %{add: n} -> {:ok, n * 2} end)
      |> Taco.run()

      {:ok, :multiply, 10}

  We chain two actions - `:add` and `:multiply`. Each action receives the
  results of previous actions in a map (first action receives an empty map),
  and (in this example) returns an `{:ok, result}` tuple, which means that
  computation was successful. Calling `Taco.run/1` on such a pipeline returns
  a tagged result of the last action.

  Note that no actions are executed until you call `Taco.run/1`. You can pass
  the taco around and run it only when the results are needed.

  ## Actions

  Actions are functions which take a map of results of previous actions as an
  argument. They are executed in the order `Taco.then/3` is called. There are
  three valid return values of an action:

  * `{:ok, result}` - the action was successful. `result` will be put in the
    map of all the results and passed to to the next action in the pipeline,
    or `Taco.run/1` will return `{:ok, tag, result}` if it was the last action
    in the pipeline
  * `{:halt, result}` - the action was successful, but further actions won't
    be executed. `Taco.run/1` will return immediately with the
    `{:ok, tag, result}` tuple
  * `{:error, error}` - the action failed. `Taco.run/1` will return immediately
    with the `{:error, tag, error, results_so_far}` tuple. `results_so_far` is
  the map of results of all the actions completed before the failing one

  ## Examples

  Successful pipeline

      iex> number = 2
      iex> Taco.new()
      ...> |> Taco.then(:add, fn _ -> {:ok, number + 3} end)
      ...> |> Taco.then(:multiply, fn %{add: n} -> {:ok, n * 2} end)
      ...> |> Taco.run()
      {:ok, :multiply, 10}


  Halting pipeline

      iex> number = 2
      iex> Taco.new()
      ...> |> Taco.then(:add, fn _ -> {:halt, number + 3} end)
      ...> |> Taco.then(:multiply, fn %{add: n} -> {:ok, n * 2} end)
      ...> |> Taco.run()
      {:ok, :add, 5}

  Failing pipeline

      iex> number = 2
      iex> Taco.new()
      ...> |> Taco.then(:add, fn _ -> {:ok, number + 3} end)
      ...> |> Taco.then(:multiply, fn _ -> {:error, "boom!"} end)
      ...> |> Taco.then(:subtract, fn %{multiply: n} -> {:ok, n - 2} end)
      ...> |> Taco.run()
      {:error, :multiply, "boom!", %{add: 5}}
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

  @doc """
  Returns a fresh, new taco
  """
  @spec new :: t
  def new, do: %__MODULE__{}

  @doc """
  Appends the action to the pipeline of the taco

  Raises `ArgumentError` when:
  * `tag` is not an atom
  * `action` is not a 1-arity function
  * action with the given `tag` is already present

  See also "Examples" section of documentation for `Taco` module.
  """
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

  @doc """
  Executes the pipeline of actions present in the taco

  Raises `ArgumentError` when no actions are present in the taco.
  """
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
