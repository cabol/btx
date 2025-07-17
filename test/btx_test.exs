defmodule BTxTest do
  use ExUnit.Case
  doctest BTx

  if Code.ensure_loaded?(JSON) do
    test "json_module" do
      assert BTx.json_module() == JSON
    end
  else
    test "json_module" do
      assert BTx.json_module() == Jason
    end
  end
end
