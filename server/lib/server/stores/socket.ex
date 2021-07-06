defmodule Server.Stores.Socket do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec get_socket(integer()) :: pid()
  def get_socket(sock_key) do
    __MODULE__
    |> Agent.get(& &1)
    |> Map.get(sock_key)
  end

  @spec add_socket(integer(), pid()) :: :ok
  def add_socket(sock_key, pid),
    do: Agent.update(__MODULE__, fn x -> Map.put(x, sock_key, pid) end)

  @spec rm_socket(integer()) :: :ok
  def rm_socket(sock_key), do: Agent.update(__MODULE__, fn x -> Map.delete(x, sock_key) end)
end
