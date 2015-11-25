Freenet for Debian/Ubuntu
=========================

This repository contains files needed to build `.deb` packages for Freenet. This
is still in an early development stage - **USE AT YOUR OWN RISK**.

In particular, the directory structure has not yet been finalised, and may be
changed in future revisions. To keep things simple, for now we make no effort
to do automatic file migrations, which means your node may lose its settings
and user data after an upgrade.

## Building

Install dependencies as listed under `Build-Depends` in `debian/control`:

    # aptitude install equivs devscripts
    # mk-build-deps -i

Then you can build a Debian package from this repository directly. Brief
instructions are to fetch or copy an existing [Bouncy Castle 1.52](https://www.bouncycastle.org/latest_releases.html)
to `bcprov-jdk15on-152.jar`, then:

    $ git submodule update --init
    $ debian/rules vcs-mk-origtargz # if it doesn't already exist
    $ debuild -uc -us

For more details, including more fine-grained tools you can use to take you
through individual parts of the build process, see the Debian New Maintainer's
Guide, Debian Developers' Reference, and various online documentation on
debhelper and javahelper. See `man fhs` and the Debian Java FAQ for a guide to
the layout of the installed files.
