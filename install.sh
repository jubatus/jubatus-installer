#!/bin/bash

MSG_VER="0.5.7"
GLOG_VER="0.3.2"
UX_VER="0.1.8"
MECAB_VER="0.99"
IPADIC_VER="2.7.0-20070801"
ZK_VER="3.4.3"
EVENT_VER="2.0.19"
PKG_VER="0.25"
RE2_VER="20121029"
PREFIX="${HOME}/local"

while getopts dip: OPT
do
  case $OPT in
    "d" ) DOWNLOAD_ONLY="TRUE" ;;
    "i" ) INSTALL_ONLY="TRUE" ;;
    "p" ) PREFIX="$OPTARG" ;;
  esac
done

download_tgz(){
    filename=${1##*/}
    if [ ! -f $filename ]; then
	wget $1
        check_result $?
    fi
}

check_result(){
    if [ $1 -ne 0 ]; then
        echo "ERROR"
        exit 1
    fi
}

check_command(){
    if ! type $1 > /dev/null ; then
        echo "command not found: $1"
        exit 1
    fi
}

export INSTALL_LOG=install.`date +%Y%m%d`.`date +%H%M`.log 
(
if [ "${INSTALL_ONLY}" != "TRUE" ]
  then
    check_command wget
    check_command git

    mkdir -p download
    cd download

    download_tgz http://msgpack.org/releases/cpp/msgpack-${MSG_VER}.tar.gz
    download_tgz http://google-glog.googlecode.com/files/glog-${GLOG_VER}.tar.gz
    download_tgz http://ux-trie.googlecode.com/files/ux-${UX_VER}.tar.bz2
    download_tgz http://mecab.googlecode.com/files/mecab-${MECAB_VER}.tar.gz
    download_tgz http://mecab.googlecode.com/files/mecab-ipadic-${IPADIC_VER}.tar.gz
    download_tgz http://ftp.riken.jp/net/apache/zookeeper/zookeeper-${ZK_VER}/zookeeper-${ZK_VER}.tar.gz
    download_tgz http://github.com/downloads/libevent/libevent/libevent-${EVENT_VER}-stable.tar.gz
    download_tgz http://pkgconfig.freedesktop.org/releases/pkg-config-${PKG_VER}.tar.gz
    download_tgz http://re2.googlecode.com/files/re2-${RE2_VER}.tgz

    git clone https://github.com/pfi/pficommon.git
    check_result $?
    cd pficommon
    git checkout 10b1ba95628b0078984d12300f9a9deb94470952
    check_result $?
    cd ..

    git clone https://github.com/jubatus/jubatus.git
    check_result $?

    cd ..
fi

if [ "${DOWNLOAD_ONLY}" != "TRUE" ]
  then
    if [ "$JUBATUS_HOME" = "" ]; then
        echo "JUBATUS_HOME is not set. Please \"source jubatus.profile\" first."
        exit 1
    fi
    check_command g++
    check_command make
    check_command tar
    check_command python

    cd download

    tar zxf msgpack-${MSG_VER}.tar.gz
    tar zxf glog-${GLOG_VER}.tar.gz
    tar jxf ux-${UX_VER}.tar.bz2
    tar zxf mecab-${MECAB_VER}.tar.gz
    tar zxf mecab-ipadic-${IPADIC_VER}.tar.gz
    tar zxf zookeeper-${ZK_VER}.tar.gz
    tar zxf libevent-${EVENT_VER}-stable.tar.gz
    tar zxf pkg-config-${PKG_VER}.tar.gz
    tar zxf re2-${RE2_VER}.tgz

    mkdir -p ${PREFIX}

    LD_LIBRARY_PATH=${PREFIX}/lib
    export LD_LIBRARY_PATH


    cd ./pkg-config-${PKG_VER}
    ./configure --prefix=${PREFIX} && make && make install
    check_result $?

    cd ../msgpack-${MSG_VER}
    ./configure --prefix=${PREFIX} && make && make install
    check_result $?

    cd ../glog-${GLOG_VER}
    ./configure --prefix=${PREFIX} && make && make install
    check_result $?

    cd ../ux-${UX_VER}
    ./waf configure --prefix=${PREFIX} && ./waf build && ./waf install
    check_result $?

    cd ../mecab-${MECAB_VER}
    ./configure --prefix=${PREFIX} --enable-utf8-only && make && make install
    check_result $?

    cd ../mecab-ipadic-${IPADIC_VER}
    MECAB_CONFIG="$PREFIX/bin/mecab-config"
    MECAB_DICDIR=`$MECAB_CONFIG --dicdir`
    ./configure --prefix=${PREFIX} --with-mecab-config=$MECAB_CONFIG --with-dicdir=$MECAB_DICDIR/ipadic --with-charset=utf-8 && make && make install
    check_result $?

    cd ../re2
    sed -i -e "s|/usr/local|${PREFIX}/|g" Makefile
    make && make install
    check_result $?

    cd ../libevent-${EVENT_VER}-stable
    ./configure --prefix=${PREFIX} && make && make install
    check_result $?

    cd ../zookeeper-${ZK_VER}/src/c
    ./configure --prefix=${PREFIX} && make && make install
    check_result $?

    cd ../../../pficommon
    ./waf configure --prefix=${PREFIX} --with-msgpack=${PREFIX} && ./waf build && ./waf install
    check_result $?

    cd ../jubatus
    ./waf configure --prefix=${PREFIX} --enable-ux --enable-mecab --enable-zookeeper && ./waf build --checkall && ./waf install
    check_result $?
fi

) 2>&1 | tee $INSTALL_LOG

# to avoid getting the exit status of "tee" command
status=${PIPESTATUS[0]}

if [ "$status" -ne 0 ]; then
  echo "all messages above are saved in \"$INSTALL_LOG\""
  exit $status
fi
