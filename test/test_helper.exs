# If the tests depend on an environment variable then add it to the list
# It follows the following format:
#   [ environment_variable: :test_tag ]
env_vars = [
  echo_server_host: :echo_server_required,
  connection_string: :rmq_required,
]


# Gets a list of unset environment variables
exclude = for {env, tag} <- env_vars do
  if Application.get_env(:hivenode, env) == nil, do: tag
end


ExUnit.start(exclude: exclude)
