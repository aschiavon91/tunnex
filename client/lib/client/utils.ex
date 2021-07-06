defmodule Client.Utils do
  @spec timestamp(atom()) :: integer
  def timestamp(typ \\ :seconds), do: :os.system_time(typ)
end
