#!/bin/bash

PYTHON_VER="2.7.15"
PREFIX="${HOME}/local"


  mkdir download
  pushd download

  wget http://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz

  tar zxf Python-${PYTHON_VER}.tgz

  pushd Python-${PYTHON_VER}
  ./configure --prefix=${PREFIX}
  make
  make install
  popd

  export PATH=${PREFIX}/bin/:$PATH
  curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
  python get-pip.py
  pip install wheel
  pip install jubatus
  pip install msgpack-rpc-python



