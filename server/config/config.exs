import Config

config :server,
  port: 22_234,
  nat: [
    %{
      name: "server0",
      from: "localhost:8000",
      to: "192.168.1.7:8080"
    },
    %{
      name: "server1",
      from: "localhost:8001",
      to: "192.168.1.7:8081"
    }
  ]

config :logger, level: :info
