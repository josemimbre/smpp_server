defmodule SmppServerTest do
  use ExUnit.Case
  doctest SmppServer

  test "greets the world" do
    assert SmppServer.hello() == :world
  end
end
