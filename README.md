Install Script of Jubatus
=========================

This script automates the process of installing Jubatus and its dependencies from source.

On supported systems, you can install all components of Jubatus using binary packages. See [http://jubat.us](http://jubat.us) for details.


Requirements
------------

* wget
* g++
* make
* tar
* python 2.x
* python-dev (for `install_python.sh`)

Due to the limitation of some libraries, jubatus-installer may fail when used with Python 3.x.
Please make sure that your `python` command points to Python 2.x.
If you are on Ubuntu 16.04 and you don't have `python` command, run `sudo apt-get install python2.7`.

Usage
-----

To install Jubatus, run:

```
$ ./install.sh
```

Jubatus is installed in `$HOME/local` by default. If you want to another directory, specify directory using `-p` option.
For example:

```
# ./install.sh -p /usr/local
```

All of options is following:

```
install.sh [-d|-i] [-p PREFIX] [-D] [-r]

 d : only download
 i : only install
 p : install path
 D : install develop branch
 r : use re2 instead of oniguruma
 x : enable debug mode
```

To use Jubatus, you need to load the environment variable from `profile` script.

```
add $PREFIX/share/jubatus/jubatus.profile to your .xshrc
```

or

```
$ source $PREFIX/share/jubatus/jubatus.profile
```


If you want to use python client, run:

```
$ ./install_python.sh
```
