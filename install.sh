#/bin/sh

MSG_VER="0.5.7"
GLOG_VER="0.3.2"
UX_VER="0.1.8"
MECAB_VER="0.99"
IPADIC_VER="2.7.0-20070801"
ZK_VER="3.4.3"
EVENT_VER="2.0.19"
PKG_VER="0.25"
RE2_VER="20121029"
PFICOMMON_VER="8fde51454af897cc971bab9033e217ff83b12f78"
JUBATUS_MPIO_VER="master"
JUBATUS_MSGPACK_RPC_VER="master"
JUBATUS_VER="master"
PREFIX="${HOME}/local"

while getopts dip:D OPT
do
  case $OPT in
    "d" ) DOWNLOAD_ONLY="TRUE" ;;
    "i" ) INSTALL_ONLY="TRUE" ;;
    "p" ) PREFIX="$OPTARG" ;;
    "D" ) JUBATUS_MPIO_VER="develop"; JUBATUS_MSGPACK_RPC_VER="develop"; JUBATUS_VER="develop" ;;
  esac
done

download_tgz(){
    filename=${1##*/}
    if [ ! -f $filename ]; then
	wget $1
        check_result $?
    fi
}

download_github_tgz(){
    filename=$2-$3.tar.gz
    if [ -f $filename -a \( $3 == "master" -o $3 == "develop" \) ]; then
        rm $filename
    fi
    if [ ! -f $filename ]; then
        wget https://github.com/$1/$2/archive/$3.tar.gz -O $2-$3.tar.gz
        check_result $?
    fi
}

check_result(){
    if [ $1 -ne 0 ]; then
        echo "ERROR"
        exit
    fi
}

check_command(){
    if ! type $1 > /dev/null ; then
        echo "command not found: $1"
        exit
    fi
}

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

    download_github_tgz pfi pficommon ${PFICOMMON_VER}
    download_github_tgz jubatus jubatus-mpio ${JUBATUS_MPIO_VER}
    download_github_tgz jubatus jubatus-msgpack-rpc ${JUBATUS_MSGPACK_RPC_VER}
    download_github_tgz jubatus jubatus ${JUBATUS_VER}

    cd ..
fi

if [ "${DOWNLOAD_ONLY}" != "TRUE" ]
  then
    if [ "$JUBATUS_HOME" = "" ]; then
        echo "JUBATUS_HOME is not set. Please \"source jubatus.profile\" first."
        exit
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

    tar zxf pficommon-${PFICOMMON_VER}.tar.gz
    tar zxf jubatus-mpio-${JUBATUS_MPIO_VER}.tar.gz
    tar zxf jubatus-msgpack-rpc-${JUBATUS_MSGPACK_RPC_VER}.tar.gz
    tar zxf jubatus-${JUBATUS_VER}.tar.gz

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

    cd ../../../pficommon-${PFICOMMON_VER}
    ./waf configure --prefix=${PREFIX} --with-msgpack=${PREFIX} && ./waf build && ./waf install
    check_result $?

    cd ../jubatus-mpio-${JUBATUS_MPIO_VER}
    ./bootstrap && ./configure --prefix=${PREFIX} && make && make install
    check_result $?

    cd ../jubatus-msgpack-rpc-${JUBATUS_MSGPACK_RPC_VER}/cpp
    ./bootstrap && ./configure --prefix=${PREFIX} && make && make install
    check_result $?
    cd ..

    cd ../jubatus-${JUBATUS_VER}
    ./waf configure --prefix=${PREFIX} --enable-ux --enable-mecab --enable-zookeeper && ./waf build --checkall && ./waf install
    check_result $?
fi

