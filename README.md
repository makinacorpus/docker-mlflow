# docker image for a mlflow tracking server

- [![Build Status](https://travis-ci.org/makinacorpus/docker-mlflow.svg?branch=master)](https://travis-ci.org/makinacorpus/docker-mlflow)
- This include the build for [dockerhub image: makinacorpus/mlflow-server](https://hub.docker.com/r/makinacorpus/mlflow-server)
    - [supported tags](https://hub.docker.com/r/makinacorpus/mlflow-server/tags)


## mlflow flavor
Run a mlflow server (tracking/registry)

- Environ variables:
    - `MLFLOW_HOST` (0.0.0.0) : host to listen on
    - `MLFLOW_PORT` (5000) : port to listen on
    - `MLFLOW_BACKEND_STORE_URI` (sqlite:////data/mlflow.sqlite) : URI to the backend store
    - `MLFLOW_ARTIFACTS_ROOT_URI` (/data/artifacts) : URI/path to store artifacts on
    - `MLFLOW_SERVER_EXTRA_ARGS` () : extra launch args

```bash
docker run -p 5000:5000 --rm -v $PWD/data:/data makinacorpus/mlflow-server:<tag>
```

## tensorflow serving flavor
- Aim of this flavor is to serve some models hosted on a mlflow+s3 setup directly via tensorflow/serving.
- This uses standard mlflow variables to connect to mlflow, download models locally then launch tensorflow on them
- compose sample

```yaml
services:
  tensorflow:
    image: makinacorpus/mlflow-server:1.11.0-tensorflowserving
    environment:
    # comma separated list of models to serve
    - "MLFLOW_MODELS=model1;model2"
    - "MLFLOW_TRACKING_URI=http://localhost:5000"
    - "MLFLOW_S3_ENDPOINT_URL=http://localhost:9000"
    - "AWS_ACCESS_KEY_ID=xx"
    - "AWS_SECRET_ACCESS_KEY=xx"
    - "AWS_STORAGE_BUCKET_NAME=mlflow"
    volumes:
    - tflow-data:/data
    ports:
    - 8500:8500
    - 8501:8501
```

