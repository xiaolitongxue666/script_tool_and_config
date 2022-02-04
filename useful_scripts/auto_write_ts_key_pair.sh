#!/bin/bash

#set -x

ts_entry=$(psql -d htyuc_local -c "select domain, pubkey, privkey from hty_apps;" | grep "ts.localhost")
ts_pubkey=$(echo $ts_entry | awk -F '|' '{print $2}' | xargs)
ts_privkey=$(echo $ts_entry | awk -F '|' '{print $3}' | xargs)
echo pubkey [$ts_pubkey]
echo privkey[$ts_privkey]

#ts_pubkey_line_num=$(grep -n "DPUB_KEY" run-java-local.sh | awk -F ':' '{print $1}')
#echo $ts_pubkey_line_num

#ts_privkey_line_num=$(grep -n "DPRIV_KEY" run-java-local.sh  | awk -F ':' '{print $1}')
#echo $ts_privkey_line_num

#replaced_pubkey_string="DPUB_KEY"
#replace_pubkey_string="    -DPUB_KEY='$ts_pubkey' \\"
#echo $replace_pubkey_string

#sed -i "" 's|.*'$replaced_pubkey_string'.*|This line is removed by the admin.|' run-java-local.sh
#sed -i -e 's|.*'$replaced_pubkey_string'.*|'"$replace_pubkey_string"'|' run-java-local.sh
#sed -i "" 's|.*'$replaced_pubkey_string'.*|'-DPUB_KEY='a7ac30cc953516b3e2c2edd5e1319070754623062fd126c400fcc579a651d6de \\''|' run-java-local.sh

#sed -i -e 's|-DPUB_KEY='.*'|'-DPUB_KEY="$ts_pubkey"'|' run-java-local.sh
sed -i -e 's|-DPUB_KEY='.*'\ |'-DPUB_KEY=\'"$ts_pubkey"\'\ '|g' run-java-local.sh
sed -i -e 's|-DPRIV_KEY='.*'\ |'-DPRIV_KEY=\'"$ts_privkey"\'\ '|g' run-java-local.sh

cat run-java-local.sh
cp run-java-local.sh.bak run-java-local.sh