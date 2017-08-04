# Taco

Composition and error handling of sequential computations, similar to
`Ecto.Multi`

[![CircleCI](https://circleci.com/gh/arkgil/taco.svg?style=svg)](https://circleci.com/gh/arkgil/taco)
[![Ebert](https://ebertapp.io/github/arkgil/taco.svg)](https://ebertapp.io/github/arkgil/taco)

Taco allows to create a chain of actions which might either succeed,
fail, or halt the execution of further actions in the pipeline.

## Usage

See the online [documentation](https://hexdocs.pm/taco/0.1.0)

## Installation

In your `mix.exs`:

```elixir
def deps do
  [
   ...
   {:taco, "~> 0.1"}
   ...
  ]
end
```

and `mix.deps get`.

## Rationale

In the Elixir world there are many solutions for composing functions which
might either fail or succeed. There is a `with` special form, there are
libraries like [OK](https://github.com/CrowdHailer/OK) which provide error
handling for the `|>` operator. Taco may not be such elegant as those
solutions, however it provides a couple of features which make it unique
in the ecosystem (for now).

1. Tagging

`with` special form allows us to match on return values of functions, and
optionally catch the values that didn't match in the `else` block:

```elixir
with {:ok, user} <- authenticate(credentials),
     {:ok, user} <- authorize(user, action) do
  :ok
else
  {:error, error} ->
    handle_error(error)
end
```

However, if both functions return `{:error, error}` on failure, there is no
way to know which one failed without wrapping the calls in a tuple:

```elixir
with {:authenticate, {:ok, user}} <- {:authenticate, authenticate(credentials)},
     {:authorize, {:ok, user}}    <- {:authorize, authorize(user, action)} do
  :ok
else
  {:authenticate, {:error, error}} ->
    handle_authentication_error(error)
  {:authorize, {:error, error}} ->
    handle_authorization_error(error)
end
```

This may become really verbose and (in my opinion) doesn't look clean.

Taco requires you to tag all the actions, so that when one of them fails,
you know exactly which one:

```elixir
Taco.new()
|> Taco.then(:authenticate, fn _ -> authenticate(user) end)
|> Taco.then(:authorize, fn %{authenticate: user} -> authorize(user) end)
|> Taco.run()

# when both succeed
{:ok, :authorize, user}
# when `:authorize` fails
{:error, :authorize, error, %{authenticate: user}}
```

2. Laziness

There is not much to be explained here. None of the actions in the taco are
executed until `Taco.run/1` is called. This allows you to pass the taco
around until you really need to get the return value.

3. Haltable pipeline

Each action in the taco may return `{:halt, result}` tuple. In such case
no further actions in the pipeline are executed, and `Taco.run/1` returns
as if the action was the last in the pipeline (`{:ok, tag, result}`).

## Similarities to `Ecto.Multi`

* Taco allows to tag each action, so that you know exactly which one has
  failed
* `Taco.then/3` operates on pure data structures, actions are executed only
  when `Taco.run/1` is called (much like `Ecto.Multi.run/3` and
  `Ecto.Repo.transaction/1`)
* Each action in the pipeline has access to results of previous actions

## License

Copyright 2017, Arkadiusz Gil

Released under MIT license.

Check [LICENSE](https://github.com/arkgil/taco/master/blob/LICENSE) file for
more information.
