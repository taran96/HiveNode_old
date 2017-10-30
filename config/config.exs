use Mix.Config

config :logger,
  backends: [{LoggerFileBackend, :file_log}]

config :logger, :file_log,
  path: System.get_env("LOGFILE")

config :hivenode,
  connection_string: System.get_env("RMQ_CONNECTION_STRING"),
  node_name: System.get_env("NODE_NAME"),
  echo_server_host: System.get_env("ECHO_SERVER_HOST"),
  echo_server_port: System.get_env("ECHO_SERVER_PORT")
