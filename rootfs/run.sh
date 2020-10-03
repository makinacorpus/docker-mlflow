#!/usr/bin/env bash
cd "$(dirname $(readlink -f "$0"))"
set -e

# failed if undefined, see dockerfile
export MLFLOW__HOST="${MLFLOW__HOST?}"
export MLFLOW__PORT="${MLFLOW__PORT?}"
export MLFLOW__BACKEND_STORE_URI="${MLFLOW__BACKEND_STORE_URI?}"
export MLFLOW__ARTIFACTS_ROOT_URI="${MLFLOW__ARTIFACTS_ROOT_URI?}"
export MLFLOW_SKIP_EXPOSE_HOST=${MLFLOW_SKIP_EXPOSE_HOST-}

die() { echo $@ >&2; exit 1; }

if ( echo "$MLFLOW__ARTIFACTS_ROOT_URI" |  egrep -q -- ^/ );then
    if [ ! -d "$MLFLOW__ARTIFACTS_ROOT_URI" ];then
        mkdir -p "$MLFLOW__ARTIFACTS_ROOT_URI"
    fi
    chown mlflow $MLFLOW__ARTIFACTS_ROOT_URI
fi
if [ -e /data ];then
    chown mlflow /data
fi
if [[ -z ${MLFLOW_SKIP_EXPOSE_HOST} ]];then
    ip -4 route list match 0/0 \
        | awk '{print $3" host.docker.internal"}' >> /etc/hosts
     export DOCKER_HOST_IP=$(ip -4 route list match 0/0 \
        | awk '{print $3}')
fi

frep mlflow.frep:/etc/supervisor.d/mlflow --overwrite

export SUPERVISORD_CONFIGS="/etc/supervisor.d/rsyslog /etc/supervisor.d/mlflow"
exec supervisord.sh
