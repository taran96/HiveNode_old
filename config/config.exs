use Mix.Config

config :logger,
  backends: [{LoggerFileBackend, :file_log}]

config :logger, :file_log,
  path: "log/debug.log"

config :hivenode,
  connection_string:  "amqp://node:nodepass@192.168.1.175:5672",
  node_name: "A"
