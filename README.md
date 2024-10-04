# myperl-tools
My Perl-Tools

Just 2c from me for the tools I use every day...

## Getting started

Perhaps you have to do this first:

```
sudo apt install a2ps libdbd-mysql-perl liblocale-gettext-perl \
                 libpoe-loop-tk-perl
```

Install all:

```
sh ./install.sh
```

Install only translate:

```
cd translate
sh ./install.sh
cd ..
```

set environment variable TRANSLATE to the langiages you want to translate to:
```
export TRANSLATE="de en fr it"
```

Install only a2ps:

```
cd a2ps
sh ./install.sh
cd ..
```

Install only myconf:

```
cd myconf
sh ./install.sh
cd ..
```

Install only mycopy:

```
cd mycopy
sh ./install.sh
cd ..
```
