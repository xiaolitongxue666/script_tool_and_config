#!/bin/bash

set -x # 调试模式

# 全局变量
sub_log_number=112

# 删除日志
rm -rf ./logs/

# 重新创建日志目录
mkdir -p ./logs/

cd ./logs/

for ((i = 0; i < $sub_log_number; i++)); do
    index=$(printf "%0*d" 3 $i)
    # printf "index is [%s]\n" $index

    sub_log_dir_name=$(printf "log_%s" $index)
    # printf "sub log dir name is [%s]\n" $sub_log_dir_name # 调试

    mkdir -p $sub_log_dir_name
done

rm -rf ./log4crc

touch ./log4crc

chmod 777 ./log4crc

# cat << EOF > 会清除之前的文本
cat << EOF > ./log4crc
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE log4c SYSTEM "">

<log4c version="1.2.4">

	<config>
		<bufsize>0</bufsize>
		<debug level="2"/>
		<nocleanup>0</nocleanup>
		<reread>1</reread>
	</config>

EOF

for ((i = 0; i < $sub_log_number; i++)); do
index=$(printf "%0*d" 3 $i)
# printf "index is [%s]\n" $index
cat << EOF >> ./log4crc
    <category name="netint_$index" priority="trace" appender="rolling_file_appender_$index"/>
    <appender name="rolling_file_appender_$index" type="rollingfile" logdir="./logs/log_$index" prefix="netint_$index" layout="dated" rollingpolicy="rolling_policy_$index"/>
    <rollingpolicy name="rolling_policy_$index" type="sizewin" maxsize="102400" maxnum="1"/>

EOF
done

# cat << EOF >> 会追加文本
cat << EOF >> ./log4crc
</log4c>
EOF

cat ./log4crc

ls -l ./log4crc
