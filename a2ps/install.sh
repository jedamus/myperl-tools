#!/usr/bin/env sh

# erzeugt Montag, 14. Dezember 2020 14:01 (C) 2020 von Leander Jedamus
# modifiziert Montag, 14. Dezember 2020 14:18 von Leander Jedamus

d=$HOME/bin
cp -Rvp a2ps.pl locale $d
cd $d
ln -svf a2ps.pl a2ps

# vim:ai sw=2

