#!/bin/bash

PREFIX="${HOME}/local"

JUBATUS_VER="0.9.2"
JUBATUS_SUM="5462a1537170c5f535b9fb7f86c03760ce95228a"

JUBATUS_CORE_VER="0.3.2"
JUBATUS_CORE_SUM="316cca49f3c0cc8b3088bffed7234d2cbf738914"

MSG_VER="0.5.9"
MSG_SUM="6efcd01f30b3b6a816887e3c543c8eba6dcfcb25"

LOG4CXX_VER="0.10.0"
LOG4CXX_SUM="d79c053e8ac90f66c5e873b712bb359fd42b648d"

APR_VER="1.5.2"
APR_SUM="2ef2ac9a8de7f97f15ef32cddf1ed7325163d84c"

APR_UTIL_VER="1.5.4"
APR_UTIL_SUM="72cc3ac693b52fb831063d5c0de18723bc8e0095"

UX_VER="0.1.9"
UX_SUM="1f5427dd1fc6052fb125959f183471e6f81f87d9"

MECAB_VER="0.996"
MECAB_SUM="15baca0983a61c1a49cffd4a919463a0a39ef127"
MECAB_URL="https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE"

IPADIC_VER="2.7.0-20070801"
IPADIC_SUM="0d9d021853ba4bb4adfa782ea450e55bfe1a229b"
IPADIC_URL="https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM"

ZK_VER="3.4.8"
ZK_SUM="51b61611a329294f75aed82f3a4517a4b6ff116f"

PKG_VER="0.28"
PKG_SUM="71853779b12f958777bffcb8ca6d849b4d3bed46"

RE2_VER="2015-06-01"
RE2_SUM="e3d41170c0ab6ddda4df9ed6efc2f5e8e667983b"

ONIG_VER="5.9.6"
ONIG_SUM="08d2d7b64b15cbd024b089f0924037f329bc7246"

JUBATUS_MPIO_VER="0.4.5"
JUBATUS_MPIO_SUM="ad4e75bf612d18d710a44e3d1a94413abf33eeb7"

JUBATUS_MSGPACK_RPC_VER="0.4.4"
JUBATUS_MSGPACK_RPC_SUM="a62582b243dc3c232aa29335d3657ecc2944df3b"


while getopts dip:Dr OPT
do
  case $OPT in
    "d" ) DOWNLOAD_ONLY="TRUE" ;;
    "i" ) INSTALL_ONLY="TRUE" ;;
    "p" ) PREFIX="$OPTARG" ;;
    "D" ) JUBATUS_MPIO_VER="develop"
          JUBATUS_MSGPACK_RPC_VER="develop"
          JUBATUS_CORE_VER="develop"
          JUBATUS_VER="develop" ;;
    "r" ) USE_RE2="TRUE" ;;
  esac
done

download_tgz(){
    filename=${1##*/}
    sum=$2
    [ ! -z "$3" ] && filename=$3

    if [ ! -f $filename ]; then
        wget -O "${filename}" $1
        check_result $?
    fi
    echo "$sum  $filename" | $shasum -c /dev/stdin
    check_result $?
}

download_github_tgz(){
    filename=$2-$3.tar.gz
    sum=$4
    if [ -f $filename -a \( $3 == "master" -o $3 == "develop" \) ]; then
        rm $filename
    fi
    if [ ! -f $filename ]; then
        wget https://github.com/$1/$2/archive/$3.tar.gz -O $2-$3.tar.gz
        check_result $?
    fi
    if [ $3 != "master" -a $3 != "develop" ]; then
        echo "$sum  $filename" | $shasum -c /dev/stdin
        check_result $?
    fi
}

# When $name is abc-def and $version is develop, echoes abc_def.
# When $name is abc-def and $version is not develop, echoes abc-def.
echo_handy_name() {
    local name=$1
    local version=$2

    if [ $version != "develop" ]; then
        echo $name | sed 's/-/_/'
    else
        echo $name
    fi
}

# This function downloads jubauts-mpio or jubatus-msgpack-rpc from download.jubat.us or GitHub.
# When a version is specified as "develop", the function downloads a tarball of develop branch from GitHub.
# Otherwise, the function downloads from download.jubat.us.
#
# The aim is to eliminate dependency to ruby and autotools when released version is specified.
# A tarball from download.jubat.us contains a configure script,
# so the tools which generate configure scripts (i.e. ruby and autotools) are not required
# when building released librariess.
download_from_proper_location_tgz() {
    local name=$2 # jubatus-mpio or jubatus-msgpack-rpc
    local version=$3
    local sum=$4

    name=`echo_handy_name $name $version`
    if [ $version = "develop" ]; then
        download_github_tgz $1 $name $version $sum
    else
        download_tgz "http://download.jubat.us/files/source/$name/$name-$version.tar.gz" $sum
    fi
}

# The aim of this function is same as the above.
extract_tarball_properly() {
    local name=$1
    local version=$2

    name=`echo_handy_name $name $version`

    tar zxf $name-$version.tar.gz
}

# The aim of this function is same as the above.
build_properly() {
    local name=$1 # jubatus-mpio or jubatus-msgpack-rpc
    local version=$2

    name=`echo_handy_name $name $version`

    pushd $name-$version
    if [ $name = "jubatus-msgpack-rpc" ]; then # develop version of jubatus-msgpack-rpc
        pushd cpp
    else
        pushd .
    fi

    if [ $version = "develop" ]; then
        ./bootstrap
    fi

    ./configure --prefix=${PREFIX} && make && make install
    local retval=$?
    popd
    popd

    return $((retval + 0))
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

check_libtoolize_command() {
    local libtoolize
    if [ `uname` = Darwin ]; then # OS X
        libtoolize="glibtoolize"
    else
        libtoolize="libtoolize"
    fi

    check_command $libtoolize
}

check_commands_to_generate_configure_script() {
    if [ $JUBATUS_MPIO_VER = "develop" -o $JUBATUS_MSGPACK_RPC_VER = "develop" ]; then
        check_command ruby
        check_command aclocal
        check_command autoconf
        check_command autoheader
        check_command automake
        check_libtoolize_command
    fi
}

check_shasum_command() {
    if type sha1sum > /dev/null 2>&1 ; then
        shasum="sha1sum"
    fi
    if type shasum > /dev/null 2>&1 ; then
        shasum="shasum"
    fi
    if [ -z $shasum ]; then
        echo "command not found: sha1sum, shasum"
        exit 1
    fi
}

makedir() {
    if [ -d $1 ]; then
        if [ ! -w $1 ]; then
            echo "unwritable directory: $1"
            exit 1
        fi
    else
        mkdir -p $1
        check_result $?
    fi
}

export INSTALL_LOG=install.`date +%Y%m%d`.`date +%H%M`.log 
(
if [ "${INSTALL_ONLY}" != "TRUE" ]
  then
    check_command wget
    check_shasum_command

    makedir download
    cd download

    download_tgz https://github.com/msgpack/msgpack-c/releases/download/cpp-${MSG_VER}/msgpack-${MSG_VER}.tar.gz ${MSG_SUM}
    download_tgz http://ftp.riken.jp/net/apache/logging/log4cxx/${LOG4CXX_VER}/apache-log4cxx-${LOG4CXX_VER}.tar.gz ${LOG4CXX_SUM}
    download_tgz http://ftp.riken.jp/net/apache//apr/apr-${APR_VER}.tar.gz ${APR_SUM}
    download_tgz http://ftp.riken.jp/net/apache//apr/apr-util-${APR_UTIL_VER}.tar.gz ${APR_UTIL_SUM}
    download_github_tgz hillbig ux-trie ${UX_VER} ${UX_SUM}
    download_tgz "${MECAB_URL}" ${MECAB_SUM} "mecab-${MECAB_VER}.tar.gz"
    download_tgz "${IPADIC_URL}" ${IPADIC_SUM} "mecab-ipadic-${IPADIC_VER}.tar.gz"
    download_tgz http://ftp.riken.jp/net/apache/zookeeper/zookeeper-${ZK_VER}/zookeeper-${ZK_VER}.tar.gz ${ZK_SUM}
    download_tgz http://pkgconfig.freedesktop.org/releases/pkg-config-${PKG_VER}.tar.gz ${PKG_SUM}
    if [ "${USE_RE2}" == "TRUE" ]; then
      download_github_tgz google re2 ${RE2_VER} ${RE2_SUM}
    else
      download_tgz https://github.com/kkos/oniguruma/releases/download/v${ONIG_VER}/onig-${ONIG_VER}.tar.gz ${ONIG_SUM}
    fi

    download_from_proper_location_tgz jubatus jubatus-mpio ${JUBATUS_MPIO_VER} ${JUBATUS_MPIO_SUM}
    download_from_proper_location_tgz jubatus jubatus-msgpack-rpc ${JUBATUS_MSGPACK_RPC_VER} ${JUBATUS_MSGPACK_RPC_SUM}
    download_github_tgz jubatus jubatus_core ${JUBATUS_CORE_VER} ${JUBATUS_CORE_SUM}
    download_github_tgz jubatus jubatus ${JUBATUS_VER} ${JUBATUS_SUM}

    cd ..
fi

if [ "${DOWNLOAD_ONLY}" != "TRUE" ]
  then
    check_commands_to_generate_configure_script
    check_command g++
    check_command make
    check_command tar
    check_command python
    check_command sed

    cd download

    tar zxf msgpack-${MSG_VER}.tar.gz
    tar zxf apache-log4cxx-${LOG4CXX_VER}.tar.gz
    tar zxf apr-${APR_VER}.tar.gz
    tar zxf apr-util-${APR_UTIL_VER}.tar.gz
    tar zxf ux-trie-${UX_VER}.tar.gz
    tar zxf mecab-${MECAB_VER}.tar.gz
    tar zxf mecab-ipadic-${IPADIC_VER}.tar.gz
    tar zxf zookeeper-${ZK_VER}.tar.gz
    tar zxf pkg-config-${PKG_VER}.tar.gz
    if [ "${USE_RE2}" == "TRUE" ]; then
      tar zxf re2-${RE2_VER}.tar.gz
    else
      tar zxf onig-${ONIG_VER}.tar.gz
    fi

    extract_tarball_properly jubatus-mpio ${JUBATUS_MPIO_VER}
    extract_tarball_properly jubatus-msgpack-rpc ${JUBATUS_MSGPACK_RPC_VER}
    tar zxf jubatus_core-${JUBATUS_CORE_VER}.tar.gz
    tar zxf jubatus-${JUBATUS_VER}.tar.gz

    makedir ${PREFIX}

    export PATH=${PREFIX}/bin:$PATH
    export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
    export LDFLAGS="-L${PREFIX}/lib"
    export LD_LIBRARY_PATH="${PREFIX}/lib"
    export DYLD_LIBRARY_PATH="${PREFIX}/lib"
    export C_INCLUDE_PATH="${PREFIX}/include"
    export CPLUS_INCLUDE_PATH="${PREFIX}/include"

    cd ./pkg-config-${PKG_VER}
    ./configure --prefix=${PREFIX} --with-internal-glib && make && make install
    check_result $?

    cd ../msgpack-${MSG_VER}
    ./configure --prefix=${PREFIX} && make && make install
    check_result $?

    cd ../apr-${APR_VER}
    ./configure --prefix=${PREFIX} && make && make install
    check_result $?

    cd ../apr-util-${APR_UTIL_VER}
    ./configure --prefix=${PREFIX} --with-apr=${PREFIX} && make && make install
    check_result $?

    cd ../apache-log4cxx-${LOG4CXX_VER}
    sed -i '18i#include <string.h>' src/main/cpp/inputstreamreader.cpp
    sed -i '18i#include <string.h>' src/main/cpp/socketoutputstream.cpp
    sed -i '19i#include <string.h>' src/examples/cpp/console.cpp
    sed -i '20i#include <stdio.h>' src/examples/cpp/console.cpp
    ./configure --prefix=${PREFIX} && make && make install
    check_result $?

    cd ../ux-trie-${UX_VER}
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

    if [ "${USE_RE2}" == "TRUE" ]; then
      cd ../re2-${RE2_VER}
      sed -i -e "s|/usr/local|${PREFIX}/|g" Makefile
      make && make install
      check_result $?
    else
      cd ../onig-${ONIG_VER}
      ./configure --prefix=${PREFIX} && make && make install
      check_result $?
    fi

    cd ../zookeeper-${ZK_VER}/src/c
    ./configure --prefix=${PREFIX} && make && make install
    check_result $?

    cd ../../..
    build_properly jubatus-mpio ${JUBATUS_MPIO_VER}
    check_result $?

    build_properly jubatus-msgpack-rpc ${JUBATUS_MSGPACK_RPC_VER}
    check_result $?

    cd jubatus_core-${JUBATUS_CORE_VER}
    if [ "${USE_RE2}" == "TRUE" ]; then
      ./waf configure --prefix=${PREFIX} --regexp-library=re2
    else
      ./waf configure --prefix=${PREFIX}
    fi
    check_result $?
    ./waf build --checkall && ./waf install
    check_result $?

    cd ../jubatus-${JUBATUS_VER}
    ./waf configure --prefix=${PREFIX} --enable-ux --enable-mecab --enable-zookeeper
    check_result $?
    ./waf build --checkall && ./waf install
    check_result $?

    cat > ${PREFIX}/share/jubatus/jubatus.profile <<EOF
# THIS FILE IS AUTOMATICALLY GENERATED

JUBATUS_HOME=${PREFIX}
export JUBATUS_HOME

PATH=\$JUBATUS_HOME/bin:\$PATH
export PATH

CPLUS_INCLUDE_PATH=\$JUBATUS_HOME/include
export CPLUS_INCLUDE_PATH

LDFLAGS=-L\$JUBATUS_HOME/lib
export LDFLAGS

LD_LIBRARY_PATH=\$JUBATUS_HOME/lib
export LD_LIBRARY_PATH

DYLD_LIBRARY_PATH=\$JUBATUS_HOME/lib
export DYLD_LIBRARY_PATH=\$JUBATUS_HOME/lib

PKG_CONFIG_PATH=\$JUBATUS_HOME/lib/pkgconfig
export PKG_CONFIG_PATH
EOF

fi

) 2>&1 | tee $INSTALL_LOG

# to avoid getting the exit status of "tee" command
status=${PIPESTATUS[0]}

if [ "$status" -ne 0 ]; then
  echo "all messages above are saved in \"$INSTALL_LOG\""
  exit $status
fi
