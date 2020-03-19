#!/bin/bash

PREFIX="${HOME}/local"

JUBATUS_VER="1.1.1"
JUBATUS_SUM="f2cc6280e47872910ac16014ef14d584721d1596"

JUBATUS_CORE_VER="1.1.1"
JUBATUS_CORE_SUM="578a31cd8292552afa1f3d17a1fbbb06170f21fe"

MSG_VER="0.5.9"
MSG_SUM="6efcd01f30b3b6a816887e3c543c8eba6dcfcb25"

LOG4CXX_VER="0.10.0"
LOG4CXX_SUM="d79c053e8ac90f66c5e873b712bb359fd42b648d"

EXPAT_VER="2.2.4"
EXPAT_SUM="3394d6390c041a8f5dec1d5fe7c4af0a23ae4504"

APR_VER="1.6.5"
APR_SUM="ebf4f15fa5003b1490550e260f5a57dc8a2ff0ac"

APR_UTIL_VER="1.6.1"
APR_UTIL_SUM="5bae4ff8f1dad3d7091036d59c1c0b2e76903bf4"

UX_VER="0.1.9"
UX_SUM="1f5427dd1fc6052fb125959f183471e6f81f87d9"

MECAB_VER="0.996"
MECAB_SUM="15baca0983a61c1a49cffd4a919463a0a39ef127"
MECAB_URL="https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE"

IPADIC_VER="2.7.0-20070801"
IPADIC_SUM="0d9d021853ba4bb4adfa782ea450e55bfe1a229b"
IPADIC_URL="https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM"

ZK_VER="3.4.14"
ZK_SUM="285a0c85112d9f99d42cbbf8fb750c9aa5474716"

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


while getopts dip:Drx OPT
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
    "x" ) ENABLE_DEBUG="TRUE" ;;
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

    ./configure CXXFLAGS=-std=gnu++98 --prefix=${PREFIX} && make clean && make && make install
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
check_operation() {
    if [ $1 -ne 0 ]; then
        echo ""
        echo "*************************************************************"
        echo "Jubatus installation failed..."
        echo "If the problem persists, try cleaning up ${PREFIX} directory."
        echo "all messages above are saved in \"$INSTALL_LOG\""
        exit $1
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
exec 3>&1
exec > $INSTALL_LOG
exec 2>&1
if [ "${INSTALL_ONLY}" != "TRUE" ]
  then
    check_command wget
    check_shasum_command

    makedir download
    (
    echo "[Downloading archives]" 1>&3
    pushd download

    echo "msgpack-${MSG_VER}.tar.gz" 1>&3
    download_tgz https://github.com/msgpack/msgpack-c/releases/download/cpp-${MSG_VER}/msgpack-${MSG_VER}.tar.gz ${MSG_SUM}
    echo "apache-log4cxx-${LOG4CXX_VER}.tar.gz" 1>&3
    download_tgz http://ftp.riken.jp/net/apache/logging/log4cxx/${LOG4CXX_VER}/apache-log4cxx-${LOG4CXX_VER}.tar.gz ${LOG4CXX_SUM}
    echo "expat-${EXPAT_VER}.tar.bz2" 1>&3
    download_tgz https://downloads.sourceforge.net/project/expat/expat/${EXPAT_VER}/expat-${EXPAT_VER}.tar.bz2 ${EXPAT_SUM}
    echo "apr-${APR_VER}.tar.gz" 1>&3
    download_tgz http://ftp.riken.jp/net/apache//apr/apr-${APR_VER}.tar.gz ${APR_SUM}
    echo "apr-util-${APR_UTIL_VER}.tar.gz" 1>&3
    download_tgz http://ftp.riken.jp/net/apache//apr/apr-util-${APR_UTIL_VER}.tar.gz ${APR_UTIL_SUM}
    echo "ux-trie-${UX_VER}.tar.gz" 1>&3
    download_github_tgz hillbig ux-trie ${UX_VER} ${UX_SUM}
    echo "mecab-${MECAB_VER}.tar.gz" 1>&3
    download_tgz "${MECAB_URL}" ${MECAB_SUM} "mecab-${MECAB_VER}.tar.gz"
    echo "mecab-ipadic-${IPADIC_VER}.tar.gz" 1>&3
    download_tgz "${IPADIC_URL}" ${IPADIC_SUM} "mecab-ipadic-${IPADIC_VER}.tar.gz"
    echo "zookeeper-${ZK_VER}.tar.gz" 1>&3
    download_tgz https://archive.apache.org/dist/zookeeper/zookeeper-${ZK_VER}/zookeeper-${ZK_VER}.tar.gz ${ZK_SUM}
    echo "pkg-config-${PKG_VER}.tar.gz" 1>&3
    download_tgz http://pkgconfig.freedesktop.org/releases/pkg-config-${PKG_VER}.tar.gz ${PKG_SUM}
    if [ "${USE_RE2}" == "TRUE" ]; then
      echo "re2-${RE2_VER}.tar.gz" 1>&3
      download_github_tgz google re2 ${RE2_VER} ${RE2_SUM}
    else
      echo "onig-${ONIG_VER}.tar.gz" 1>&3
      download_tgz https://github.com/kkos/oniguruma/releases/download/v${ONIG_VER}/onig-${ONIG_VER}.tar.gz ${ONIG_SUM}
    fi

    echo "jubatus-mpio-${JUBATUS_MPIO_VER}.tar.gz" 1>&3
    download_from_proper_location_tgz jubatus jubatus-mpio ${JUBATUS_MPIO_VER} ${JUBATUS_MPIO_SUM}
    echo "jubatus-msgpack-rpc-${JUBATUS_MSGPACK_RPC_VER}.tar.gz" 1>&3
    download_from_proper_location_tgz jubatus jubatus-msgpack-rpc ${JUBATUS_MSGPACK_RPC_VER} ${JUBATUS_MSGPACK_RPC_SUM}
    echo "jubatus_core-${JUBATUS_CORE_VER}.tar.gz" 1>&3
    download_github_tgz jubatus jubatus_core ${JUBATUS_CORE_VER} ${JUBATUS_CORE_SUM}
    echo "jubatus-${JUBATUS_VER}.tar.gz" 1>&3
    download_github_tgz jubatus jubatus ${JUBATUS_VER} ${JUBATUS_SUM}

    popd
    )
    check_operation $? 1>&3
fi

if [ "${DOWNLOAD_ONLY}" != "TRUE" ]
  then
    check_commands_to_generate_configure_script
    check_command g++
    check_command make
    check_command tar
    check_command bzip2
    check_command python
    check_command sed

    (
    echo "[Installing dependencies]" 1>&3
    pushd download

    tar zxf msgpack-${MSG_VER}.tar.gz
    tar zxf apache-log4cxx-${LOG4CXX_VER}.tar.gz
    tar jxf expat-${EXPAT_VER}.tar.bz2
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

    echo "Installing pkg-config-${PKG_VER}" 1>&3
    pushd pkg-config-${PKG_VER}
    ./configure CXXFLAGS=-std=gnu++98 --prefix=${PREFIX} --with-internal-glib && make clean && make && make install
    check_result $?
    popd

    echo "Installing msgpack-${MSG_VER}" 1>&3
    pushd msgpack-${MSG_VER}
    ./configure CXXFLAGS=-std=gnu++98 --prefix=${PREFIX} && make clean && make && make install
    check_result $?
    popd

    echo "Installing expat-${EXPAT_VER}" 1>&3
    pushd expat-${EXPAT_VER}
    ./configure CXXFLAGS=-std=gnu++98 --prefix=${PREFIX} --without-xmlwf && make clean && make && make install
    check_result $?
    popd

    echo "Installing apr-${APR_VER}" 1>&3
    pushd apr-${APR_VER}
    ./configure CXXFLAGS=-std=gnu++98 --prefix=${PREFIX} && make clean && make && make install
    check_result $?
    popd

    echo "Installing apr-util-${APR_UTIL_VER}" 1>&3
    pushd apr-util-${APR_UTIL_VER}
    ./configure CXXFLAGS=-std=gnu++98 --prefix=${PREFIX} --with-apr=${PREFIX} && make clean && make && make install
    check_result $?
    popd

    echo "Installing apache-log4cxx-${LOG4CXX_VER}" 1>&3
    pushd apache-log4cxx-${LOG4CXX_VER}
    sed -i '18i#include <string.h>' src/main/cpp/inputstreamreader.cpp
    sed -i '18i#include <string.h>' src/main/cpp/socketoutputstream.cpp
    sed -i '19i#include <string.h>' src/examples/cpp/console.cpp
    sed -i '20i#include <stdio.h>' src/examples/cpp/console.cpp
    ./configure CXXFLAGS=-std=gnu++98 --prefix=${PREFIX} && make clean && make && make install
    check_result $?
    popd

    echo "Installing ux-trie-${UX_VER}" 1>&3
    pushd ux-trie-${UX_VER}
    ./waf configure --prefix=${PREFIX} && ./waf clean && ./waf build && ./waf install
    check_result $?
    popd

    echo "Installing mecab-${MECAB_VER}" 1>&3
    pushd mecab-${MECAB_VER}
    ./configure CXXFLAGS=-std=gnu++98 --prefix=${PREFIX} --enable-utf8-only && make clean && make && make install
    check_result $?
    popd

    echo "Installing mecab-ipadic-${IPADIC_VER}" 1>&3
    pushd mecab-ipadic-${IPADIC_VER}
    MECAB_CONFIG="$PREFIX/bin/mecab-config"
    MECAB_DICDIR=`$MECAB_CONFIG --dicdir`
    ./configure CXXFLAGS=-std=gnu++98 --prefix=${PREFIX} --with-mecab-config=$MECAB_CONFIG --with-dicdir=$MECAB_DICDIR/ipadic --with-charset=utf-8 && make clean && make && make install
    check_result $?
    popd

    if [ "${USE_RE2}" == "TRUE" ]; then
     echo "Installing re2-${RE2_VER}" 1>&3
     pushd re2-${RE2_VER}
     sed -i -e "s|/usr/local|${PREFIX}/|g" Makefile
     make clean && make && make install
     check_result $?
    else
     echo "Installing onig-${ONIG_VER}" 1>&3
     pushd onig-${ONIG_VER}
     ./configure CXXFLAGS=-std=gnu++98 --prefix=${PREFIX} && make clean && make && make install
     check_result $?
    fi
    popd

    echo "Installing zookeeper-${ZK_VER}" 1>&3
    pushd zookeeper-${ZK_VER}/zookeeper-client/zookeeper-client-c
    ./configure CXXFLAGS=-std=gnu++98 CFLAGS=-Wno-error --prefix=${PREFIX} && make clean && make && make install
    check_result $?
    popd
    popd

    pushd download
    echo "[Installing jubatus-components]" 1>&3
    echo "Installing jubatus-mpio-${JUBATUS_MPIO_VER}" 1>&3
    build_properly jubatus-mpio ${JUBATUS_MPIO_VER}
    check_result $?

    echo "Installing jubatus-msgpack-rpc-${JUBATUS_MSGPACK_RPC_VER}" 1>&3
    build_properly jubatus-msgpack-rpc ${JUBATUS_MSGPACK_RPC_VER}
    check_result $?

    echo "Installing jubatus-core-${JUBATUS_CORE_VER}" 1>&3
    pushd jubatus_core-${JUBATUS_CORE_VER}
    CONFIGURE_OPT="CXXFLAGS=-std=gnu++98 --prefix=${PREFIX} --libdir=${PREFIX}/lib"
    if [ "${USE_RE2}" == "TRUE" ]; then
      CONFIGURE_OPT="${CONFIGURE_OPT} --regexp-library=re2"
    fi

    if [ "${ENABLE_DEBUG}" == "TRUE" ]; then
      CONFIGURE_OPT="${CONFIGURE_OPT} --enable-debug"
    fi

    ./waf configure ${CONFIGURE_OPT}
    check_result $?
    ./waf clean && ./waf build --checkall && ./waf install
    check_result $?
    popd

    echo "Installing jubatus-${JUBATUS_VER}" 1>&3
    pushd jubatus-${JUBATUS_VER}
    CONFIGURE_OPT="CXXFLAGS=-std=gnu++98 --prefix=${PREFIX} --libdir=${PREFIX}/lib --enable-ux --enable-mecab --enable-zookeeper"
    if [ "${ENABLE_DEBUG}" == "TRUE" ]; then
      CONFIGURE_OPT="${CONFIGURE_OPT} --enable-debug"
    fi

    ./waf configure ${CONFIGURE_OPT}
    check_result $?
    ./waf clean && ./waf build --checkall && ./waf install
    check_result $?
    popd

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
    )
    check_operation $? 1>&3
fi


exec 1>&3


cat << _EOF_

//=============================================================//
//                                                             //
//   _________         ___                                     //
//   \____   _|       | /             ___I_I___                //
//       |  |         | |             \__^ ^__/        ____    //
//       |  |         | | ___    ___  __ | |          / __/    //
//       |  | |-|  |-|| |/   \  /   \| | | | |^|  |^|| (__     //
//       |  | | |  | ||    ^  ||  ^    | | | | |  | | \__ \    //
//       |  | | \_/  ||    O  ||  O    | | |_| \_/  | ___) |   //
//       |  |  \__/|_||_|\___/  \___/|_| |__/ \__/|_| \___/    //
//       | /                                                   //
//      / /                                                    //
//     |/                                                      //
//                                                             //
//=============================================================//
              Jubatus ${JUBATUS_VER} Installation Completed!

  Add the following lines to your ~/.bashrc or ~/.zshrc:

    # Jubatus
    source ${PREFIX}/share/jubatus/jubatus.profile

  Tutorials and examples can be found at:

    * http://jubat.us/en/tutorial.html
    * https://github.com/jubatus/jubatus-example/

  Have fun!  -- Jubatus Team
_EOF_
