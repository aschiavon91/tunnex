import Config

config :logger, :console,
  format: "\n[$time][$level] $message $metadata\n",
  metadata: [:file]

config :client,
  host: "192.168.1.7",
  server_cfg: [
    host: "192.168.1.7",
    port: 22234,
    pool: 5
  ]
