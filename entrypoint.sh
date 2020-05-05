#!/usr/bin/env bash
set -e

# Compatibility with older helm charts that used to run crond.
if [[ "$1" == "crond" ]]; then
  exec /usr/local/bin/clean-airflow-logs
fi

# Airflow subcommand
CMD=$2

url_parse_regex="[^:]+://([^@/]*@)?([^/:]*):?([0-9]*)/?"

# Wait for postgres then init the db
if [[ -n $AIRFLOW__CORE__SQL_ALCHEMY_CONN  ]]; then
  # Wait for database port to open up
  [[ ${AIRFLOW__CORE__SQL_ALCHEMY_CONN} =~ $url_parse_regex ]]
  HOST=${BASH_REMATCH[2]}
  PORT=${BASH_REMATCH[3]}
  echo "Waiting for host: ${HOST} ${PORT}"
  while ! nc -w 1 -z "${HOST}" "${PORT}"; do
    sleep 0.001
  done
fi

if [[ -n $AIRFLOW__CELERY__BROKER_URL ]] && [[ $CMD =~ ^(scheduler|worker|flower)$ ]]; then
  # Wait for database port to open up
  [[ ${AIRFLOW__CELERY__BROKER_URL} =~ $url_parse_regex ]]
  HOST=${BASH_REMATCH[2]}
  PORT=${BASH_REMATCH[3]}
  echo "Waiting for host: ${HOST} ${PORT}"
  while ! nc -w 1 -z "${HOST}" "${PORT}"; do
    sleep 0.001
  done
fi

if [[ $CMD == "webserver" ]]; then
  airflow sync_perm
fi

# Run the original command
exec "$@"