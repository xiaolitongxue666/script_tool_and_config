#!/bin/bash

# 脚本所在目录，用于解析 gitignore 模板路径（引用 git_templates 下模板）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_IGNORE_TEMPLATES_DIR="${SCRIPT_DIR}/../../git_templates/default_gitignore_files"

# 项目名称使用当前目录名
project_path=$(pwd)
project_name="${project_path##*/}"
echo "项目名称: $project_name"

# 检查输入参数数量
if [ $# != 1 ]; then

cat << EOF
usage: up [--level <n> | -n <levels>][--help][--version]

Report bugs to:
up home page:
EOF

exit

fi

# 创建 C 项目类型
if [ $1 = "c" ];then
    echo "创建 C 项目"
    project_type="c"
fi

# 创建 C++ 项目类型
if [ $1 = "cpp" ];then
    echo "创建 C++ 项目"
    project_type="cpp"
fi

# 目录
# 如果目录不存在，则创建它
# build 目录包含不同项目的构建脚本
if [ ! -d "./build" ]; then
  mkdir -p ./build
  echo -e "#!/bin/sh" >> ./build/cmake_all_project.sh
  echo -e "" >> ./build/cmake_all_project.sh
  echo -e "cmake .." >> ./build/cmake_all_project.sh
  echo -e "make clean" >> ./build/cmake_all_project.sh
  echo -e "make" >> ./build/cmake_all_project.sh
fi

# 如果目录不存在，则创建它
# tools 目录包含外部工具
if [ ! -d "./tools" ]; then
  mkdir -p ./tools
fi

# 如果目录不存在，则创建它
# work_note 目录包含项目关键笔记
if [ ! -d "./work_note" ]; then
  mkdir -p ./work_note
fi

# 如果目录不存在，则创建它
# src 目录包含所有源代码
if [ ! -d "./src" ]; then
  mkdir -p ./src
  echo "请将源代码文件添加到 src 目录，然后再次运行此脚本！"
fi

# 文件
# 如果文件不存在，则创建它
git_ignore_file_path="./.gitignore"
if [ ! -f "$git_ignore_file_path" ]; then
  touch "$git_ignore_file_path"

  # 写入默认忽略规则
  # IDE(Idea) 数据
  echo -e "# Personal intermediate dirs and files" >> $git_ignore_file_path
  echo -e ".idea/" >> $git_ignore_file_path
  echo -e "cmake-build-debug/" >> $git_ignore_file_path
  # 构建脚本和 cmake 数据
  echo -e "./generate_project.sh" >> $git_ignore_file_path
  echo -e "./ls_dirs_name.sh" >> $git_ignore_file_path
  echo -e "build/" >> $git_ignore_file_path
  # 新行
  echo -e "\n" >> $git_ignore_file_path
  # 项目类型默认忽略中间文件（从 git_templates 引用）
  if [ "$project_type" = "c" ]; then
    cat "${GIT_IGNORE_TEMPLATES_DIR}/git_ignore_default_c.txt" >> $git_ignore_file_path
  else
    cat "${GIT_IGNORE_TEMPLATES_DIR}/git_ignore_default_cpp.txt" >> $git_ignore_file_path
  fi
fi

# CMakeLists.txt 更新
cmake_list_file_path="./CMakeLists.txt"

# 重新创建 cmake 列表文件
rm -rf $cmake_list_file_path
touch $cmake_list_file_path

# 写入 cmake 列表文件
echo -e "cmake_minimum_required(VERSION 2.8)" >> $cmake_list_file_path
echo -e "project($project_name)" >> $cmake_list_file_path
echo -e "set(CMAKE_CXX_STANDARD 11)" >> $cmake_list_file_path
echo -e "set(CMAKE_EXPORT_COMPILE_COMMANDS ON)" >> $cmake_list_file_path

# 新行
echo -e "\n" >> $cmake_list_file_path

# 包含目录
echo -e "include_directories(./src)" >> $cmake_list_file_path
./ls_dirs_name.sh ./src | awk '{print "include_directories("$0")" }' >> $cmake_list_file_path

# 新行
echo -e "\n" >> $cmake_list_file_path

# 源文件
echo -e "set(src_dir_list_files ./src/*.c ./src/*.h " >> $cmake_list_file_path
./ls_dirs_name.sh ./src | awk '{print " "$0"/*c "$0"/*h " }' >> $cmake_list_file_path
echo -e ")" >> $cmake_list_file_path
echo -e "file(GLOB_RECURSE SOURCES \${src_dir_list_files})" >> $cmake_list_file_path

# 新行
echo -e "\n" >> $cmake_list_file_path

# cmake 调试：列出所有源文件
echo -e "message("---Debug Echo---")" >> $cmake_list_file_path
echo -e "foreach(src_file \${SOURCES})" >> $cmake_list_file_path
echo -e "    message(src_file="\${src_file}")" >> $cmake_list_file_path
echo -e "endforeach()" >> $cmake_list_file_path

# 新行
echo -e "\n" >> $cmake_list_file_path

# 最终可执行文件
echo -e "add_executable($project_name \${SOURCES})" >> $cmake_list_file_path