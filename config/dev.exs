use Mix.Config

config :logger, level: :debug

config :smpp_server, SmppServer.MC,
  system_id: "SMPPServer01",
  port: 2775,
  max_connections: 30
