defmodule Client.Application do
  @moduledoc false

  use Application

  alias Client.Stores.Socket

  @impl true
  def start(_type, _args) do
    children = [
      Socket
    ]

    opts = [strategy: :one_for_one, name: Client.Supervisor]
    Supervisor.start_link(children ++ selector_pool(), opts)
  end

  defp selector_pool() do
    poolsize = Application.get_env(:client, :poolsize, 5)

    1..poolsize
    |> Enum.map(fn x ->
      Supervisor.child_spec({Client.Selector, name: :"selector/#{x}"}, id: :"selector/#{x}")
    end)
  end
end
