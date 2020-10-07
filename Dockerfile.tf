# size of the image is dependant of using --squash docker build flag !
ARG MLFLOW__VERSION="1.11.0"
FROM makinacorpus/mlflow-server:$MLFLOW__VERSION
ARG MLFLOW__VERSION="1.11.0"
LABEL maintainer "Mathieu Le Marec Pasquet <kiorky@cryptelium.net>"
ENTRYPOINT ["/code/tensorflowserving.py"]
