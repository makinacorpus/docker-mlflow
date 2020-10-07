# size of the image is dependant of using --squash docker build flag !
FROM corpusops/tensorflow-serving
LABEL maintainer "Mathieu Le Marec Pasquet <kiorky@cryptelium.net>"
ARG LANG="fr_FR.UTF-8"
ARG TZ="Europe/Paris"
ARG MLFLOW__VERSION="1.11.0"
ENV TZ="$TZ" \
    LANG="$LANG"\
    MLFLOW__VERSION="$MLFLOW__VERSION" \
    PYTHONUNBUFFERED="1" \
    DEBIAN_FRONTEND="noninteractive" \
    MLFLOW__HOST="0.0.0.0" \
    MLFLOW__PORT="5000" \
    MLFLOW__BACKEND_STORE_URI="sqlite:////data/mlflow.sqlite" \
    MLFLOW__ARTIFACTS_ROOT_URI="/data/artifacts" \
    MLFLOW__SERVER_EXTRA_ARGS=""

# setup project timezone, dependencies, user & workdir, gosu
ADD apt.txt /code/
RUN bash -ec ': \
  && apt-get update -qq \
  && apt-get install -qq -y $(grep -vE "^\s*#" /code/apt.txt  | tr "\n" " ") \
  && apt-get clean all && apt-get autoclean \
  && if ! ( getent passwd mlflow &>/dev/null);then useradd -ms /bin/bash mlflow --uid 1000;fi \
  && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone'

ADD --chown=mlflow:mlflow req*txt /code/
RUN : \
  && cd /code \
  && sed -i -re "s/mlflow==.*/mlflow==$MLFLOW__VERSION/g" requirements.txt \
  && python3 -m pip install -U --no-cache-dir setuptools wheel pip \
  && python3 -m pip install -U --no-cache-dir -r requirements.txt

# do not expose if artifacts are on a remote store (s3)
# VOLUME [/data]

ADD --chown=mlflow:mlflow rootfs/ /code/

RUN bash -ec ': \
  && apt-get update -qq \
  && apt-get remove -y --autoremove $(grep -vE "^\s*#" /code/apt.txt \
    | egrep "(build-essential|-dev)$" |tr "\n" " ") \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean -y all && apt-get -y autoclean'

# final cleanup
ENTRYPOINT ["/code/run.sh"]
