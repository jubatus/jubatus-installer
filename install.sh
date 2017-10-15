#!/bin/bash

PREFIX="${HOME}/local"

JUBATUS_VER="1.0.5"
JUBATUS_SUM="90bb107282789bc0156fe5daf62e2bab5dac71eb"

JUBATUS_CORE_VER="1.0.5"
JUBATUS_CORE_SUM="4775febcde440032c9f4eaac0845b83eb96c63ad"

MSG_VER="0.5.9"
MSG_SUM="6efcd01f30b3b6a816887e3c543c8eba6dcfcb25"

LOG4CXX_VER="0.10.0"
LOG4CXX_SUM="d79c053e8ac90f66c5e873b712bb359fd42b648d"

EXPAT_VER="2.2.4"
EXPAT_SUM="3394d6390c041a8f5dec1d5fe7c4af0a23ae4504"

APR_VER="1.6.2"
APR_SUM="20aa9eb9925637d54fe84b49d8497766cf0e11f0"

APR_UTIL_VER="1.6.0"
APR_UTIL_SUM="3c085a570610d02b11974e8e3efeb85784523c46"

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

    ./configure --prefix=${PREFIX} && make clean && make && make install
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
    pushd download

    download_tgz https://github.com/msgpack/msgpack-c/releases/download/cpp-${MSG_VER}/msgpack-${MSG_VER}.tar.gz ${MSG_SUM}
    download_tgz http://ftp.riken.jp/net/apache/logging/log4cxx/${LOG4CXX_VER}/apache-log4cxx-${LOG4CXX_VER}.tar.gz ${LOG4CXX_SUM}
    download_tgz https://downloads.sourceforge.net/project/expat/expat/${EXPAT_VER}/expat-${EXPAT_VER}.tar.bz2 ${EXPAT_SUM}
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

    popd
fi

if [ "${DOWNLOAD_ONLY}" != "TRUE" ]
  then
    check_commands_to_generate_configure_script
    check_command g++
    check_command make
    check_command tar
    check_command python
    check_command sed

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

    pushd pkg-config-${PKG_VER}
    ./configure --prefix=${PREFIX} --with-internal-glib && make clean && make && make install
    check_result $?
    popd

    pushd msgpack-${MSG_VER}
    ./configure --prefix=${PREFIX} && make clean && make && make install
    check_result $?
    popd

    pushd expat-${EXPAT_VER}
    ./configure --prefix=${PREFIX} --without-xmlwf && make clean && make && make install
    check_result $?
    popd

    pushd apr-${APR_VER}
    ./configure --prefix=${PREFIX} && make clean && make && make install
    check_result $?
    popd

    pushd apr-util-${APR_UTIL_VER}
    ./configure --prefix=${PREFIX} --with-apr=${PREFIX} && make clean && make && make install
    check_result $?
    popd

    pushd apache-log4cxx-${LOG4CXX_VER}
    sed -i '18i#include <string.h>' src/main/cpp/inputstreamreader.cpp
    sed -i '18i#include <string.h>' src/main/cpp/socketoutputstream.cpp
    sed -i '19i#include <string.h>' src/examples/cpp/console.cpp
    sed -i '20i#include <stdio.h>' src/examples/cpp/console.cpp
    ./configure --prefix=${PREFIX} && make clean && make && make install
    check_result $?
    popd

    pushd ux-trie-${UX_VER}
    ./waf configure --prefix=${PREFIX} && ./waf clean && ./waf build && ./waf install
    check_result $?
    popd

    pushd mecab-${MECAB_VER}
    ./configure --prefix=${PREFIX} --enable-utf8-only && make clean && make && make install
    check_result $?
    popd

    pushd mecab-ipadic-${IPADIC_VER}
    MECAB_CONFIG="$PREFIX/bin/mecab-config"
    MECAB_DICDIR=`$MECAB_CONFIG --dicdir`
    ./configure --prefix=${PREFIX} --with-mecab-config=$MECAB_CONFIG --with-dicdir=$MECAB_DICDIR/ipadic --with-charset=utf-8 && make clean && make && make install
    check_result $?
    popd

    if [ "${USE_RE2}" == "TRUE" ]; then
      pushd re2-${RE2_VER}
      sed -i -e "s|/usr/local|${PREFIX}/|g" Makefile
      make clean && make && make install
      check_result $?
    else
      pushd onig-${ONIG_VER}
      ./configure --prefix=${PREFIX} && make clean && make && make install
      check_result $?
    fi
    popd

    pushd zookeeper-${ZK_VER}/src/c
    ./configure --prefix=${PREFIX} && make clean && make && make install
    check_result $?
    popd

    build_properly jubatus-mpio ${JUBATUS_MPIO_VER}
    check_result $?

    build_properly jubatus-msgpack-rpc ${JUBATUS_MSGPACK_RPC_VER}
    check_result $?

    pushd jubatus_core-${JUBATUS_CORE_VER}
    CONFIGURE_OPT="--prefix=${PREFIX} --libdir=${PREFIX}/lib"
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

    pushd jubatus-${JUBATUS_VER}
    CONFIGURE_OPT="--prefix=${PREFIX} --libdir=${PREFIX}/lib --enable-ux --enable-mecab --enable-zookeeper"
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

fi

) 2>&1 | tee $INSTALL_LOG

# to avoid getting the exit status of "tee" command
status=${PIPESTATUS[0]}

if [ "$status" -ne 0 ]; then
  echo ""
  echo "*************************************************************"
  echo "Jubatus installation failed..."
  echo "If the problem persists, try cleaning up ${PREFIX} directory."
  echo "all messages above are saved in \"$INSTALL_LOG\""
  exit $status
fi

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
