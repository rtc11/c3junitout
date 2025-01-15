# PREREQUISITES
- ripgrep

# INSTALL
1. compile
> c3c compile --optlevel=max jo.c3

2. add executable to path (e.g. symlink)
> ln -s /path/to/executable/jo /usr/local/bin/jo

# USAGE
Show files

> jo list
> jo list utsjekk
> jo list utsjekk.utbetaling

Show stdout

> jo 
> jo utsjekk
> jo utsjekk.utbetaling
