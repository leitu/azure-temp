#! /bin/bash
chars='@#$%&_+='
{ </dev/urandom LC_ALL=C grep -ao '[A-Za-z0-9]' \
    | head -n$((RANDOM % 8 + 20))
        echo ${chars:$((RANDOM % ${#chars})):5}   # Random special char.
    } \
    | sort | tr -d '\n'
