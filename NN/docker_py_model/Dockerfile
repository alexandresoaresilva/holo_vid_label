#FROM ubuntu:20.04
#FROM python:3.8.11-slim
FROM python:3.8.11-slim-buster

RUN apt-get update -y

RUN mkdir model_files
COPY ./start.sh ./start.sh

COPY ./d2_model_load.py model_files/d2_model_load.py
COPY ./model_server.py model_files/model_server.py
COPY ./detector_py_200ep.pth model_files/detector_py_200ep.pth
# COPY ./install_jemalloc.sh ./install_jemalloc.sh
# RUN bash ./install_jemalloc.sh
# gcc compiler and opencv prerequisites
RUN apt-get -y install nano git build-essential libglib2.0-0 libsm6 libxext6 libxrender-dev
RUN apt-get install -y python3-opencv

# Detectron2 prerequisites
RUN pip install flask flask-cors requests opencv-python jsonpickle numpy Pillow

RUN pip install torch==1.9.0+cpu torchvision==0.10.0+cpu torchaudio==0.9.0 -f https://download.pytorch.org/whl/torch_stable.html
RUN pip install cython
# RUN pip install -U 'git+https://github.com/cocodataset/cocoapi.git#subdirectory=PythonAPI'

# Detectron2 - CPU copy
RUN python -m pip install detectron2 -f https://dl.fbaipublicfiles.com/detectron2/wheels/cpu/torch1.9/index.html

# Development packages


CMD bash ./start.sh