defmodule Client.Stores.Socket do
  use Agent

  def start_link(_opts), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  @spec get_socket(integer()) :: pid()
  def get_socket(key) do
    __MODULE__
    |> Agent.get(& &1)
    |> Map.get(key)
  end

  @spec add_socket(integer(), pid()) :: :ok
  def add_socket(key, pid), do: Agent.update(__MODULE__, fn x -> Map.put(x, key, pid) end)

  @spec rm_socket(integer()) :: :ok
  def rm_socket(key), do: Agent.update(__MODULE__, fn x -> Map.delete(x, key) end)
end
