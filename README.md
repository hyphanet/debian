Freenet for Debian/Ubuntu
=========================

This repository contains files needed to build `.deb` packages for Freenet. This
is still in an early development stage - **USE AT YOUR OWN RISK**.

In particular, the directory structure has not yet been finalised, and may be
changed in future revisions. To keep things simple, for now we make no effort
to do automatic file migrations, which means your node may lose its settings
and user data after an upgrade.

See `README.update` for the information on the latest state of the package.

## Building under Debian Wheezy

Install dependencies as listed under `Build-Depends` in `debian/control`:

    # apt-get install cdbs debhelper javahelper quilt adduser git-core\
    default-jdk ant ant-optional ant-contrib jflex junit4 libcommons-collections3-java\
    libcommons-compress-java libdb-je-java libecj-java libservice-wrapper-java\
    service-wrapper

[GWT](http://packages.debian.org/search?suite=default&section=all&arch=any&searchon=names&keywords=gwt+java) is required and is only available in Squeeze. As a dirty workaround the gwt jars have been added to debian/. Bouncy Castle 1.52 is also [required](https://emu.freenetproject.org/pipermail/devl/2012-October/036588.html), but [Wheezy](http://packages.debian.org/wheezy/libbcprov-java) has Bouncy Castle 1.44. [Jessie](http://packages.debian.org/jessie/libbcprov-java) and [Sid](http://packages.debian.org/sid/libbcprov-java) has 1.49. The build-freenet-daemon.sh now downloads bouncycastle 1.52 by default


Run the build script `./build-freenet-daemon`. Built packages will be put into
this directory.


## Known issues / quirks

The build script will run the unit tests twice, since `dpkg-buildpackage` runs
both the `build` and `binary` targets of `debian/rules` specifically, even though
the latter already includes the former. The only way around this would be to
change the build script - either `debian/rules` or `fred/build-clean.xml` - to
detect if the tests have already been run, but this is hard in the former case
and inappropriate in the latter case.
