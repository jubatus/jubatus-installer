#/bin/sh

PYTHON_VER="2.7.2"
PREFIX="${HOME}/local"


  mkdir download
  cd download

  wget http://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz
  wget http://peak.telecommunity.com/dist/ez_setup.py

  tar zxf Python-${PYTHON_VER}.tgz

  cd Python-${PYTHON_VER}
  ./configure --prefix=${PREFIX}
  make
  make install

  cd ..
  python ez_setup.py
  easy_install pip
  pip install jubatus
  pip install msgpack-rpc-python



