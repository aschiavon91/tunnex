defmodule Server.Utils do
  @moduledoc false

  @spec timestamp(atom()) :: integer
  def timestamp(type \\ :seconds), do: :os.system_time(type)

  def generete_socket_key, do: Enum.random(0..65_535)
end
