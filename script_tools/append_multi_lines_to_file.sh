#/bin/bash

set -x

kernel="2.6.39"
distro="xyz"

cat >> append_multi_lines_to_file.txt << EOL
line 1, ${kernel}
line 2,
line 3, ${distro}
line ...
EOL
