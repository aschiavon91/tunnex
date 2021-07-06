defmodule Server.Stores.IPSocket do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec get_socket(binary()) :: pid
  def get_socket(ip) do
    __MODULE__
    |> Agent.get(& &1)
    |> Map.get(ip)
    |> (fn
          nil -> nil
          socks -> Enum.random(socks)
        end).()
  end

  @spec add_socket(binary(), pid) :: :ok
  def add_socket(ip, pid),
    do: Agent.update(__MODULE__, fn x -> Map.update(x, ip, [pid], &[pid | &1]) end)

  @spec rm_socket(binary()) :: :ok
  def rm_socket(ip), do: Agent.update(__MODULE__, fn x -> Map.delete(x, ip) end)
end
