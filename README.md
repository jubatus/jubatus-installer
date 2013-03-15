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
* python
* python-dev (for `install_python.sh`)


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
install.sh -dip

 d : only download
 i : only install
 p : install path
 D : install develop branch
```

To use Juatus, you need to load the environment variable from `profile` script.

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
