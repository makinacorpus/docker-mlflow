# docker image for a mlflow tracking server

- [![Build Status](https://travis-ci.org/makinacorpus/docker-mlflow.svg?branch=master)](https://travis-ci.org/makinacorpus/docker-mlflow)
- This include the build for [dockerhub image: makinacorpus/mlflow-server](https://hub.docker.com/r/makinacorpus/mlflow-server)
    - [supported tags](https://hub.docker.com/r/makinacorpus/mlflow-server/tags)


## Using the image
- Environ variables:
    - `MLFLOW_HOST` (0.0.0.0) : host to listen on
    - `MLFLOW_PORT` (5000) : port to listen on
    - `MLFLOW_BACKEND_STORE_URI` (sqlite:////data/mlflow.sqlite) : URI to the backend store
    - `MLFLOW_ARTIFACTS_ROOT_URI` (/data/artifacts) : URI/path to store artifacts on
    - `MLFLOW_SERVER_EXTRA_ARGS` () : extra launch args


Run example

```bash
docker run -p 5000:5000 --rm -v $PWD/data:/data makinacorpus/mlflow-server:<tag>
```

