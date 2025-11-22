#!/usr/bin/env bash
# NETINT (c) 2020
# 此脚本用于帮助客户安装 Netint 软件和固件

function end_script() {
    printf "\n"
    printf "已停止 t4xx_quick_installer.sh\n"
    trap - EXIT
    exit 0
}

function install_yasm() {
    rc=1
    sudo wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz \
    -O yasm-1.3.0.tar.gz &&
    tar -zxf yasm-1.3.0.tar.gz && cd yasm-1.3.0/ &&
    sudo ./configure && sudo make && sudo make install && cd .. &&
    rc=0
    return $rc
}

function install_libxcoder() {
    # 确定使用旧版还是新版 nvme 模块
    nvme_ver=$(modinfo -F version nvme)
    if [[ $(printf "${nvme_ver}\n0.10\n" | sort -V | tail -n 1) == "0.10" ]]; then
        libxcoder_build_flags="--with-old-nvme-driver"
    else
        libxcoder_build_flags=""
    fi

    rc=1
    sudo rm -rf libxcoder &> /dev/null
    cp -r release/libxcoder ./ && cd libxcoder && sh build.sh ${libxcoder_build_flags} && cd .. && rc=0
    sudo rm /dev/shm/LCK_CODERS /dev/shm/SHM_CODERS /dev/shm/lck_[de][0-9] \
    /dev/shm/shm_[de][0-9] /dev/shm/NI* &> /dev/null
    timeout -s KILL 5 libxcoder/build/init_rsrc 2>&1 > /dev/null
    return $rc
}

# $1 - 要使用的 FFmpeg 版本（例如: 4.2.1）
function install_ffmpeg_ver() {
    rc=1

    echo "安装路径: ./FFmpeg/"
    echo "注意: 这将在基础 ${ver_num} FFmpeg 之上安装 NETINT-T4XX FFmpeg-${ver_num} 补丁"
    echo "      任何自定义配置必须手动集成"
    echo ""
    echo "使用 --enable-static 编译 FFmpeg 以静态链接 FFmpeg 库，或使用"
    echo "--enable-shared 如果打算直接与 libavcodec 接口。"
    echo -e "\e[33m选择选项:\e[0m"
    select opt in "使用 --enable-static 编译" "使用 --enable-shared 编译"; do
        case $opt in
            "使用 --enable-static 编译")
                extra_build_flag=""
                break
            ;;
            "使用 --enable-shared 编译")
                extra_build_flag=" --shared"
                if ls /usr/local/lib/libav*.so* /usr/local/lib/libswscale.so* \
                      /usr/local/lib/libswresample.so* /usr/local/lib/libpostproc.so* &> /dev/null; then
                    echo "/usr/local/lib/ 中的旧 libav*、libswscale、libswresample、libpostproc 包"
                    echo "将干扰新安装的 FFmpeg。"
                    
                    echo -e "\e[33m选择选项:\e[0m"
                    select opt in "删除旧的 FFmpeg 库" "继续而不删除" "返回主菜单"; do
                        case $opt in
                            "删除旧的 FFmpeg 库")
                                sudo rm /usr/local/lib/libav*.so* /usr/local/lib/libswscale.so* \
                                        /usr/local/lib/libswresample.so* /usr/local/lib/libpostproc.so*
                                break
                            ;;
                            "继续而不删除")
                                break
                            ;;
                            "返回主菜单")
                                return $rc
                            ;;
                            *) echo -e "\e[31m无效选择！\e[0m"
                            ;;
                        esac
                    done
                fi
                break
            ;;
            *) echo -e "\e[31m无效选择！\e[0m"
            ;;
        esac
    done
    
    echo "正在从 github 下载 FFmpeg-${ver_num}..." &&
    sudo rm -rf FFmpeg/ &> /dev/null; mkdir FFmpeg/
    # 确定目标是标签/分支名称还是提交 SHA1，并相应地下载
    if  [[ `echo ${1} | grep -P "^[0-9a-fA-F]{7,}$"` != "" ]]; then
        git clone https://gitee.com/mirrors/ffmpeg.git FFmpeg/
        cd FFmpeg/ && git checkout ${1} && cd ..
    else
        git clone -b ${1} --depth=1 https://gitee.com/mirrors/ffmpeg.git FFmpeg/
    fi
    echo "正在将 FFmpeg-${ver_num} 的 NETINT 补丁复制到安装目录..." &&
    cp release/FFmpeg-${ver_num}_t4[03xX][28xX]_patch FFmpeg/ &&
    cd FFmpeg/ &&
    patch -t -p 1 < FFmpeg-${ver_num}_t4[03xX][28xX]_patch &&
    echo "正在编译 FFmpeg-${ver_num}..." &&
    sudo make clean &> /dev/null || true &&
    sh build_ffmpeg.sh --ffprobe${extra_build_flag} &&
    sudo make install &&
    chmod 755 run_ffmpeg.sh &&
    cd .. &&
    rc=0
    sudo ldconfig
    return $rc
}

# $1 - 返回码
# $2 - 要打印的前缀
function print_eval_rc() {
    if [[ $1 == 0 ]]; then
        echo -e "\e[32m${2} 运行成功\e[0m"
    else
        echo -e "\e[31m${2} 失败\e[0m"
    fi
    return $1
}

trap end_script EXIT

base_dir=$(pwd)
fw_pack=$(ls T4[03xX][28xX]_V*.*.*.tar.gz | sort -V | tail -n 1)
ffmpeg_pack=$(ls Codensity_T4[03xX][28xX]_Software_Release_V*.*.*.tar.gz | sort -V | tail -n 1)

export LD_LIBRARY_PATH=/usr/local/lib/
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/

echo "欢迎使用 NETINT t4xx_quick_installer 工具"
echo "请将您要安装的固件和 FFmpeg 发布包放在与此脚本相同的目录中"
echo -e "在此找到的最新固件发布包:     \e[33m${fw_pack}\e[0m"
echo -e "在此找到的最新 FFmpeg 发布包: \e[33m${ffmpeg_pack}\e[0m"
if [[ $(echo ${fw_pack} | grep -Poh "(?<=T4[03xX][28xX]_V)\w\.\w\.\w.*(?=.tar.gz)") != $(echo ${ffmpeg_pack} | grep -Poh "(?<=Codensity_T4[03xX][28xX]_Software_Release_V)\w\.\w\.\w.*(?=.tar.gz)") ]]; then
    echo -e "\e[31m警告\e[0m: 固件和软件版本不匹配"
fi
read -p "按 [Y/y] 确认使用这两个发布包。 " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "请删除您不想使用的发布包文件，然后重试。"
    end_script
fi

# 解压软件发布包以自动发现 FFmpeg 版本
echo "正在删除旧的 './release/' 文件夹..."
sudo rm -rf release
echo "正在解压新的固件和软件发布文件夹"
tar -zxf $ffmpeg_pack
tar -zxf $fw_pack

options=("设置环境变量"
         "解锁 CPU 调速器"
         "安装 Linux 先决条件包 (CentOS)"
         "安装 Linux 先决条件包 (Ubuntu)"
         "安装 NVMe CLI"
         "安装 Libxcoder")

for ff_patch in release/FFmpeg-*_t4xx_patch; do
    ver_num=$(echo ${ff_patch} | grep -Poh 'release/FFmpeg-\K[^_]*(?=_t4xx_patch)')
    if [[ $ver_num == '*' ]]; then
        continue;
    fi
    options+=("安装 FFmpeg-${ver_num}")
done

options+=("固件更新"
          "退出")

# 主菜单循环
COLUMNS=20
while true; do
    cd $base_dir
    echo -e "\e[33m选择选项:\e[0m"
    select opt in "${options[@]}"; do
        case $opt in
            "设置环境变量")
                echo -e "\e[33m您选择了 $REPLY，即 $opt\e[0m"

                sudo grep -qxF 'Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin' /etc/sudoers ||
                sudo `which sed` -i '/^Defaults    secure_path = /s/$/:\/usr\/local\/sbin:\/usr\/local\/bin/' /etc/sudoers &&
                sudo grep -qxF 'Defaults    env_keep += "PKG_CONFIG_PATH"' /etc/sudoers ||
                sudo sh -c "echo 'Defaults    env_keep += \"PKG_CONFIG_PATH\"' >> /etc/sudoers"

                export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/ &&
                export LD_LIBRARY_PATH=/usr/local/lib/ &&
                sudo grep -qxF '/usr/local/lib' /etc/ld.so.conf ||
                sudo sh -c 'echo "/usr/local/lib" >> /etc/ld.so.conf'
                sudo ldconfig

                print_eval_rc $? "${opt}"
                break
            ;;
            "解锁 CPU 调速器")
                echo -e "\e[33m您选择了 $REPLY，即 $opt\e[0m"
                grep -qxF 'for (( i=0; i<`nproc`; i++ )); do sudo sh -c "echo performance > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor"; done 2> /dev/null' ~/.bashrc ||
                echo 'for (( i=0; i<`nproc`; i++ )); do sudo sh -c "echo performance > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor"; done 2> /dev/null' >> ~/.bashrc
                print_eval_rc $? "${opt}"
                break
            ;;
            "安装 Linux 先决条件包 (CentOS)")
                echo -e "\e[33m您选择了 $REPLY，即 $opt\e[0m"
                sudo yum --enablerepo=extras install -y epel-release &&
                sudo yum install -y pkgconfig git redhat-lsb-core make gcc &&
                # sudo yum install -y yasm
                install_yasm
                print_eval_rc $? "${opt}"
                break
            ;;
            "安装 Linux 先决条件包 (Ubuntu)")
                echo -e "\e[33m您选择了 $REPLY，即 $opt\e[0m"
                sudo apt-get install -y pkg-config git gcc &&
                # sudo apt-get install -y yasm
                install_yasm
                print_eval_rc $? "${opt}"
                break
            ;;
            "安装 NVMe CLI")
                echo -e "\e[33m您选择了 $REPLY，即 $opt\e[0m"
                git clone -b v1.6 --depth=1 https://gitee.com/mirrors/nvme-cli.git &&
                cd nvme-cli*/ && sudo make && sudo make install && cd ..
                print_eval_rc $? "${opt}"
                break
            ;;
            "安装 Libxcoder")
                echo -e "\e[33m您选择了 $REPLY，即 $opt\e[0m"
                install_libxcoder
                print_eval_rc $? "Libxcoder 安装"
                break
            ;;
            安装\ FFmpeg-*)
                echo -e "\e[33m您选择了 $REPLY，即 $opt\e[0m"
                # 从 $opt 获取 FFmpeg 版本号
                ver_num=$(echo ${opt} | grep -Poh '安装 FFmpeg-\K.*')
                install_ffmpeg_ver $ver_num
                print_eval_rc $? "FFmpeg 安装"
                break
            ;;
            "固件更新")
                echo -e "\e[33m您选择了 $REPLY，即 $opt\e[0m"
                sudo tar -zxf $fw_pack
                cd ${fw_pack%.tar.gz} && sudo ./t4xx_auto_upgrade.sh &&
                cd .. &&
                print_eval_rc $? "${opt}"
                break
            ;;
            "退出")
                exit
            ;;
            *) echo -e "\e[31m无效选择！\e[0m"
            ;;
        esac
    done
done

