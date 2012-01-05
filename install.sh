#!/bin/sh

PREFIX="${HOME}/local"

PYTHON_VER="2.7.2"
MSG_VER="0.5.7"
MSGP_VER="0.1.10"
GLOG_VER="0.3.1"
UX_VER="0.1.6"
MECAB_VER="0.99"
IPADIC_VER="2.7.0-20070801"
ZK_VER="3.3.3"
ZKC_VER="2.2.0"
PKG_VER="0.18"

wget http://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz
wget http://msgpack.org/releases/cpp/msgpack-${MSG_VER}.tar.gz
wget http://pypi.python.org/packages/source/m/msgpack-python/msgpack-python-${MSGP_VER}.tar.gz
wget http://google-glog.googlecode.com/files/glog-${GLOG_VER}-1.tar.gz
wget http://ux-trie.googlecode.com/files/ux-${UX_VER}.tar.bz2
wget http://mecab.googlecode.com/files/mecab-${MECAB_VER}.tar.gz
wget http://mecab.googlecode.com/files/mecab-ipadic-${IPADIC_VER}.tar.gz
wget http://hypertable.org/pub/re2.tgz
wget http://ftp.riken.jp/net/apache/zookeeper/zookeeper-${ZK_VER}/zookeeper-${ZK_VER}.tar.gz
wget http://pkgconfig.freedesktop.org/releases/pkgconfig-${PKG_VER}.tar.gz

git clone git://github.com/pfi/pficommon.git
git clone git://github.com/jubatus/jubatus.git

tar zxf Python-${PYTHON_VER}.tgz
tar zxf msgpack-${MSG_VER}.tar.gz
tar zxf msgpack-python-${MSGP_VER}.tar.gz
tar zxf glog-${GLOG_VER}-1.tar.gz
tar jxf ux-${UX_VER}.tar.bz2
tar zxf mecab-${MECAB_VER}.tar.gz
tar zxf mecab-ipadic-${IPADIC_VER}.tar.gz
tar zxf re2.tgz
tar zxf zookeeper-${ZK_VER}.tar.gz
tar zxf pkgconfig-${PKG_VER}.tar.gz

mkdir -p ${PREFFIX}

LD_LIBRARY_PATH=${PREFIX}/lib
export LD_LIBRARY_PATH

cd Python-${PYTHON_VER}
./configure --prefix=${PREFIX}
make
make install

cd ../pkgconfig-${PKG_VER}
./configure --prefix=${PREFIX}
make
make install

cd ../msgpack-${MSG_VER}
./configure --prefix=${PREFIX}
make
make install

cd ../msgpack-python-${MSGP_VER}
python setup.py install

cd ../glog-${GLOG_VER}
./configure --prefix=${PREFIX}
make
make install

cd ../ux-${UX_VER}
./waf configure --prefix=${PREFIX}
./waf build
./waf install

cd ../mecab-${MECAB_VER}
./configure --prefix=${PREFIX} --enable-utf8-only
make
make install

cd ../mecab-ipadic-${IPADIC_VER}
./configure --prefix=${PREFIX} --with-charset=utf8
make
make install

cd ../re2
sed -i -e "s|/usr/local|${PREFIX}/|g" Makefile
make
make install

cd ../zookeeper-${ZK_VER}/src/c
./configure --prefix=${PREFIX}
make
make install

cd ../../../pficommon
./waf configure --prefix=${PREFIX} --with-msgpack=${PREFIX}
./waf build
./waf install

cd ../jubatus
./waf configure --prefix=${PREFIX} --enable-ux --enable-mecab
./waf build --checkall
./waf install

