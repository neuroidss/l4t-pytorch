# Copyright (c) 2020, NVIDIA CORPORATION. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

#FROM ubuntu@sha256:a8878539376d57d89dc7e8034dd8ecb16ebce4693da48b0d8ea2890efd097848
#COPY ./qemu-aarch64-static /usr/bin/

ARG BASE_IMAGE=nvcr.io/nvidia/l4t-base:r32.5.0
#ARG BASE_IMAGE=nvcr.io/nvidia/l4t-base:r32.4.4
#ARG PYTORCH_IMAGE
#ARG TENSORFLOW_IMAGE

#FROM ${PYTORCH_IMAGE} as pytorch
#FROM ${TENSORFLOW_IMAGE} as tensorflow
FROM ${BASE_IMAGE}


#
# setup environment
#
ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_HOME="/usr/local/cuda"
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"
ENV LLVM_CONFIG="/usr/bin/llvm-config-9"
ARG MAKEFLAGS=-j6

ENV HOME=/headless
WORKDIR $HOME


RUN printenv


#
# apt packages
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
#          python3-pip \
#		  python3-dev \
#          python3-matplotlib \
		  build-essential \
		  gfortran \
		  git \
		  cmake \
		  curl \
		  libopenblas-dev \
		  liblapack-dev \
		  libblas-dev \
		  libhdf5-serial-dev \
		  hdf5-tools \
		  libhdf5-dev \
		  zlib1g-dev \
		  zip \
		  libjpeg8-dev \
		  libopenmpi2 \
          openmpi-bin \
          openmpi-common \
		  protobuf-compiler \
          libprotoc-dev \
		llvm-9 \
          llvm-9-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

#
# OpenCV
#
ARG L4T_APT_KEY
ARG L4T_APT_SOURCE

#COPY jetson-ota-public.asc /etc/apt/trusted.gpg.d/jetson-ota-public.asc

RUN apt-get update \
    && apt-get install -y wget

RUN apt-get install -y ca-certificates

RUN wget https://www.python.org/ftp/python/3.7.10/Python-3.7.10.tgz \
    && tar -xzvf ./Python-3.7.10.tgz

RUN wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.0.tar.gz \
    && tar -xzvf ./openmpi-4.1.0.tar.gz

RUN git clone -b 4.5.1 --recursive https://github.com/opencv/opencv

RUN apt-get update \
    && apt-get install -y tcl-dev tk-dev \
    && apt-get install -y libreadline-gplv2-dev \
       libncursesw5-dev libssl-dev libsqlite3-dev \
       tk-dev libgdbm-dev libc6-dev libbz2-dev

RUN cd ./Python-3.7.10 \
    && ./configure \
    && make -j8 \
    && make install

RUN pip3 install -U pip

RUN apt-get install -y \
        build-essential \
        cmake \
        git \
        gfortran \
        libatlas-base-dev \
        libavcodec-dev \
        libavformat-dev \
        libavresample-dev \
        libcanberra-gtk3-module \
        libdc1394-22-dev \
        libeigen3-dev \
        libglew-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer-plugins-good1.0-dev \
        libgstreamer1.0-dev \
        libgtk-3-dev \
        libjpeg-dev \
        libjpeg8-dev \
        libjpeg-turbo8-dev \
        liblapack-dev \
        liblapacke-dev \
        libopenblas-dev \
        libpng-dev \
        libpostproc-dev \
        libswscale-dev \
        libtbb-dev \
        libtbb2 \
        libtesseract-dev \
        libtiff-dev \
        libv4l-dev \
        libxine2-dev \
        libxvidcore-dev \
        libx264-dev \
        pkg-config \
#        python-dev \
#        python-numpy \
#        python3-dev \
#        python3-numpy \
#        python3-matplotlib \
        qv4l2 \
        v4l-utils \
        v4l2ucp \
        zlib1g-dev

RUN pip3 install wheel \
    && pip3 install matplotlib numpy

RUN cd ./openmpi-4.1.0 \
    && ./configure --with-cuda=/usr/local/cuda \
    && make -j8 \
    && make install

RUN apt-get install -y libopenblas-dev libopenblas-base liblapacke-dev \
    ccache

RUN git clone -b v2.4.0 --recursive https://github.com/uclouvain/openjpeg

RUN cd ./openjpeg \
    && mkdir build \
    && cd ./build \
    && cmake .. \
    && make -j8 \
    && make install

RUN git clone -b v0.3.13 --recursive https://github.com/xianyi/OpenBLAS

RUN apt install -y libfftw3-dev

RUN cd ./OpenBLAS \
    && make -j8 \
    && make install


RUN cd ./opencv \
    && mkdir build \
    && cd ./build \
    && cmake -DPYTHON_DEFAULT_EXECUTABLE=$(which python3) .. \
    && make -j8 \
    && make install



# if you are updating an existing checkout
#git submodule sync
#git submodule update --init --recursive

RUN update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1 \
    && update-alternatives --install /usr/bin/python python /usr/local/bin/python3.7 2 \
    && update-alternatives  --set python /usr/local/bin/python3.7

RUN pip3 install pybind11 --ignore-installed
RUN pip3 install onnx --verbose
RUN pip3 install scipy --verbose
RUN pip3 install scikit-learn --verbose
RUN pip3 install pandas --verbose
RUN pip3 install pycuda --verbose
RUN pip3 install numba --verbose

RUN pip3 install cython --verbose

#
# CuPy
#
ARG CUPY_NVCC_GENERATE_CODE="arch=compute_53,code=sm_53;arch=compute_62,code=sm_62;arch=compute_72,code=sm_72"
ENV CUB_PATH="/opt/cub"
#ARG CFLAGS="-I/opt/cub"
#ARG LDFLAGS="-L/usr/lib/aarch64-linux-gnu"

RUN git clone https://github.com/NVlabs/cub opt/cub && \
    git clone -b v8.0.0b4 https://github.com/cupy/cupy cupy && \
    cd cupy && \
    pip3 install fastrlock && \
    python3 setup.py install --verbose && \
    cd ../ && \
    rm -rf cupy

#
# JupyterLab
#
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    pip3 install jupyter jupyterlab==2.2.9 --verbose && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager

RUN jupyter lab --generate-config
RUN python3 -c "from notebook.auth.security import set_password; set_password('nvidia', '/root/.jupyter/jupyter_notebook_config.json')"

RUN pip3 install numpy ninja pyyaml setuptools cmake cffi typing_extensions future six requests dataclasses

ENV USE_OPENCV=1
ENV USE_FFMPEG=1
ENV USE_LMDB=1 

RUN git clone -b v1.7.0 --recursive https://github.com/pytorch/pytorch

RUN cd pytorch \
    && python3 setup.py install


CMD /bin/bash -c "jupyter lab --ip 0.0.0.0 --port 8888 --allow-root &> /var/log/jupyter.log" & \
        echo "allow 10 sec for JupyterLab to start @ http://$(hostname -I | cut -d' ' -f1):8888 (password nvidia)" && \
        echo "JupterLab logging location:  /var/log/jupyter.log  (inside the container)" && \
        /bin/bash

