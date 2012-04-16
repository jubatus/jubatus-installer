#/bin/sh

MSG_VER="0.5.7"
GLOG_VER="0.3.1"
UX_VER="0.1.8"
MECAB_VER="0.99"
IPADIC_VER="2.7.0-20070801"
ZK_VER="3.3.4"
EVENT_VER="2.0.18"

PREFIX="${HOME}/local"

while getopts dip: OPT
do
  case $OPT in
    "d" ) DWONLOAD_ONLY="TRUE" ;;
    "i" ) INSTALL_ONLY="TRUE" ;;
    "p" ) PREFIX="$OPTARG" ;;
  esac
done

if [ "${INSTALL_ONLY}" != "TRUE" ]
  then
    mkdir download
    cd download

    wget http://msgpack.org/releases/cpp/msgpack-${MSG_VER}.tar.gz
    wget http://google-glog.googlecode.com/files/glog-${GLOG_VER}-1.tar.gz
    wget http://ux-trie.googlecode.com/files/ux-${UX_VER}.tar.bz2
    wget http://mecab.googlecode.com/files/mecab-${MECAB_VER}.tar.gz
    wget http://mecab.googlecode.com/files/mecab-ipadic-${IPADIC_VER}.tar.gz
    wget http://ftp.riken.jp/net/apache/zookeeper/zookeeper-${ZK_VER}/zookeeper-${ZK_VER}.tar.gz
    wget https://github.com/downloads/libevent/libevent/libevent-${EVENT_VER}-stable.tar.gz
    hg clone https://re2.googlecode.com/hg re2

    git clone git://github.com/pfi/pficommon.git
    git clone git://github.com/jubatus/jubatus.git

  cd ..
fi

if [ "${DOWNLOAD_ONLY}" != "TRUE" ]
  then
    cd download

    tar zxf msgpack-${MSG_VER}.tar.gz
    tar zxf glog-${GLOG_VER}-1.tar.gz
    tar jxf ux-${UX_VER}.tar.bz2
    tar zxf mecab-${MECAB_VER}.tar.gz
    tar zxf mecab-ipadic-${IPADIC_VER}.tar.gz
    tar zxf zookeeper-${ZK_VER}.tar.gz
    tar zxf libevent-${EVENT_VER}-stable.tar.gz

    mkdir -p ${PREFFIX}

    LD_LIBRARY_PATH=${PREFIX}/lib
    export LD_LIBRARY_PATH


    cd ./msgpack-${MSG_VER}
    ./configure --prefix=${PREFIX}
    make
    make install

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

    cd ../libevent-${EVENT_VER}-stable
    ./configure --prefix=${PREFIX}
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
    ./waf configure --prefix=${PREFIX} --enable-ux --enable-mecab --enable-zookeeper
    ./waf build --checkall
    ./waf install
fi

