use Mix.Config

config :logger,
  backends: [{LoggerFileBackend, :file_log}]

config :logger, :file_log,
  path: "log/debug.log"

