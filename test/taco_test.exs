defmodule TacoTest do
  use ExUnit.Case
  doctest Taco

  test "new/0 returns an empty taco" do
    taco = Taco.new

    assert %{} == taco.actions
    assert [] == taco.order
  end

  describe "run/1" do
    test "an empty taco" do
      taco = Taco.new

      assert_raise ArgumentError, fn ->
        Taco.run(taco)
      end
    end

    test "successful taco" do
      taco =
        Taco.new()
        |> Taco.then(:action1, fn _ -> {:ok, 2} end)
        |> Taco.then(:action2, fn %{action1: n} -> {:ok, n * 2} end)

      assert {:ok, :action2, 4} == Taco.run(taco)
    end

    test "halting taco" do
      taco =
        Taco.new()
        |> Taco.then(:action1, fn _ -> {:halt, 2} end)
        |> Taco.then(:action2, fn %{action1: n} -> {:ok, n * 2} end)

      assert {:ok, :action1, 2} == Taco.run(taco)
    end

    test "failing taco" do
      taco =
        Taco.new()
        |> Taco.then(:action1, fn _ -> {:ok, 2} end)
        |> Taco.then(:action2, fn _ -> {:error, "boom!"} end)
        |> Taco.then(:action3, fn _ -> {:ok, 4} end)

      assert {:error, :action2, "boom!", %{action1: 2}} == Taco.run(taco)
    end
  end
end
