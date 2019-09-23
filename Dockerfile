FROM tiangolo/uvicorn-gunicorn:python3.7-alpine3.8

# Make directores suited to you application
WORKDIR /app

# RUN apt-get update
# RUN apt-get upgrade -y
# RUN apt-get install -y cmake clang make gcc g++ libc-dev

ENV  LIBSVM_VERSION     "324"
ENV  LIBLINEAR_VERSION  "230"
ENV  LIGHTGBM_VERSION   "2.2.3"

RUN set -x \
    && apk update \
    && apk --no-cache add \
    libstdc++ \
    && apk --no-cache add --virtual .builddeps \
    build-base \
    ca-certificates \
    cmake \
    wget \ 
    g++ \
    musl-dev \
    ## libsvm
    && wget -q -O - https://github.com/cjlin1/libsvm/archive/v${LIBSVM_VERSION}.tar.gz \
    | tar -xzf - -C / \
    && cd /libsvm-${LIBSVM_VERSION} \
    && make all lib \
    && cp svm-train svm-predict svm-scale /usr/local/bin/ \
    && cp libsvm.so* /usr/local/lib/ \
    ## liblinear
    && wget -q -O - https://github.com/cjlin1/liblinear/archive/v${LIBLINEAR_VERSION}.tar.gz \
    | tar -xzf - -C / \
    && cd /liblinear-${LIBLINEAR_VERSION} \
    && make all lib \
    && cp train predict /usr/local/bin/ \
    && cp liblinear.so* /usr/local/lib/ \
    ## lightgbm
    && apk --no-cache add \
    libgomp \ 
    libstdc++ \
    && wget -q -O - https://github.com/Microsoft/LightGBM/archive/v${LIGHTGBM_VERSION}.tar.gz \
    | tar -xzf - -C / \
    ## cli
    # && cd /LightGBM-*/ \
    # && mkdir build \
    # && cd build \
    # && cmake .. \
    # && make -j2 \
    # && make install \
    ## python package (unstable)
    && cd /LightGBM-*/python-package \
    && python setup.py install \
    ## clean
    && apk del .builddeps \
    && rm -rf \
    /liblinear* \
    /libsvm* \
    /LightGBM-*

RUN apk add --no-cache --allow-untrusted --repository http://dl-3.alpinelinux.org/alpine/edge/testing hdf5 hdf5-dev
RUN apk --no-cache --update-cache add gcc gfortran python python-dev py-pip build-base wget freetype-dev libpng-dev openblas-dev
RUN ln -s /usr/include/locale.h /usr/include/xlocale.h

# Copy and install requirements
COPY requirements.txt /app
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copy contents from your local to your docker container
COPY ./app /app
