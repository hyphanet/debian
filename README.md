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

[GWT](http://packages.debian.org/search?suite=default&section=all&arch=any&searchon=names&keywords=gwt+java) is required but is not available in the Wheezy repos, and the sid version (2.4.1) is currently outdated and [buggy](https://code.google.com/p/google-web-toolkit/issues/detail?id=7561).

That leaves the Squeeze version of GWT:

Add `APT::Default-Release "wheezy";` to a file (maybe something like `80default-release`) in `/etc/apt/apt.conf.d/` so that upgrades don't downgrade to Squeeze.
Add Squeeze main repo, such as: `deb http://ftp.us.debian.org/debian/ squeeze main` to `/etc/apt/sources.list/`

    apt-get update
    apt-get -t squeeze install libgwt-user-java libgwt-dev-java

Run the build script `./build-freenet-daemon`. Built packages will be put into
this directory.


## Known issues / quirks

The build script will run the unit tests twice, since `dpkg-buildpackage` runs
both the `build` and `binary` targets of `debian/rules` specifically, even though
the latter already includes the former. The only way around this would be to
change the build script - either `debian/rules` or `fred/build-clean.xml` - to
detect if the tests have already been run, but this is hard in the former case
and inappropriate in the latter case.
