FROM python:3.9
LABEL maintainer="USER <lukasz.pruss@ardigen.com>"
LABEL org.opencontainers.image.source=https://github.com/ardigen/nasqq
LABEL org.opencontainers.image.description="python_utils"

COPY requirements.txt .

RUN apt-get update && apt-get install -y build-essential procps

RUN pip install --no-cache-dir ipython && \
    pip install --no-cache-dir -r requirements.txt

COPY ml_helpers.py /bin
