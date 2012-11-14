#/bin/sh

MSG_VER="0.5.7"
GLOG_VER="0.3.2"
UX_VER="0.1.8"
MECAB_VER="0.99"
IPADIC_VER="2.7.0-20070801"
ZK_VER="3.4.3"
EVENT_VER="2.0.19"
PKG_VER="0.25"
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
        exit
    fi
}

if [ "${INSTALL_ONLY}" != "TRUE" ]
  then
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

    hg clone https://re2.googlecode.com/hg re2
    check_result $?

    git clone https://github.com/pfi/pficommon.git
    check_result $?

    git clone https://github.com/jubatus/jubatus.git
    check_result $?

    cd ..
fi

if [ "${DOWNLOAD_ONLY}" != "TRUE" ]
  then
    cd download

    tar zxf msgpack-${MSG_VER}.tar.gz
    tar zxf glog-${GLOG_VER}.tar.gz
    tar jxf ux-${UX_VER}.tar.bz2
    tar zxf mecab-${MECAB_VER}.tar.gz
    tar zxf mecab-ipadic-${IPADIC_VER}.tar.gz
    tar zxf zookeeper-${ZK_VER}.tar.gz
    tar zxf libevent-${EVENT_VER}-stable.tar.gz
    tar zxf pkg-config-${PKG_VER}.tar.gz

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
    ./configure --prefix=${PREFIX} --with-charset=utf8 && make && make install
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

