#!/usr/bin/env bash
# NETINT (c) 2020
# This script is intended to help customers install Netint software and firmware

function end_script() {
    printf "\n"
    printf "Stopped t4xx_quick_installer.sh\n"
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
    # determine whether old or new nvme module is to be used
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

# $1 - FFmpeg version to use (eg. 4.2.1)
function install_ffmpeg_ver() {
    rc=1

    echo "Installation Path: ./FFmpeg/"
    echo "Note: This will install NETINT-T4XX FFmpeg-${ver_num} patch ontop base ${ver_num} FFmpeg"
    echo "      Any customizations must be integrated manually"
    echo ""
    echo "Compile FFmpeg with --enable-static to statically link FFmpeg libraries, or with"
    echo "--enable-shared if intending to interface with libavcodec directly."
    echo -e "\e[33mChoose an option:\e[0m"
    select opt in "Compile with --enable-static" "Compile with --enable-shared"; do
        case $opt in
            "Compile with --enable-static")
                extra_build_flag=""
                break
            ;;
            "Compile with --enable-shared")
                extra_build_flag=" --shared"
                if ls /usr/local/lib/libav*.so* /usr/local/lib/libswscale.so* \
                      /usr/local/lib/libswresample.so* /usr/local/lib/libpostproc.so* &> /dev/null; then
                    echo "Old libav*, libswscale, libswresample, libpostproc packages in "
                    echo "/usr/local/lib/ will interfere with new FFmpeg installed."
                    
                    echo -e "\e[33mChoose an option:\e[0m"
                    select opt in "Remove old FFmpeg libs" "Continue without removal" "Return to main menu"; do
                        case $opt in
                            "Remove old FFmpeg libs")
                                sudo rm /usr/local/lib/libav*.so* /usr/local/lib/libswscale.so* \
                                        /usr/local/lib/libswresample.so* /usr/local/lib/libpostproc.so*
                                break
                            ;;
                            "Continue without removal")
                                break
                            ;;
                            "Return to main menu")
                                return $rc
                            ;;
                            *) echo -e "\e[31\Invalid choice!\e[0m"
                            ;;
                        esac
                    done
                fi
                break
            ;;
            *) echo -e "\e[31\Invalid choice!\e[0m"
            ;;
        esac
    done
    
    echo "Downloading FFmpeg-${ver_num} from github..." &&
    sudo rm -rf FFmpeg/ &> /dev/null; mkdir FFmpeg/
    # Determine if target is a tag/branch name or commit SHA1. Download accordingly
    if  [[ `echo ${1} | grep -P "^[0-9a-fA-F]{7,}$"` != "" ]]; then
        git clone https://gitee.com/mirrors/ffmpeg.git FFmpeg/
        cd FFmpeg/ && git checkout ${1} && cd ..
    else
        git clone -b ${1} --depth=1 https://gitee.com/mirrors/ffmpeg.git FFmpeg/
    fi
    echo "Copying NETINT patch for FFmpeg-${ver_num} to installation directory..." &&
    cp release/FFmpeg-${ver_num}_t4[03xX][28xX]_patch FFmpeg/ &&
    cd FFmpeg/ &&
    patch -t -p 1 < FFmpeg-${ver_num}_t4[03xX][28xX]_patch &&
    echo "Compiling FFmpeg-${ver_num}..." &&
    sudo make clean &> /dev/null || true &&
    sh build_ffmpeg.sh --ffprobe${extra_build_flag} &&
    sudo make install &&
    chmod 755 run_ffmpeg.sh &&
    cd .. &&
    rc=0
    sudo ldconfig
    return $rc
}

# $1 - rc
# $2 - prefix to print
function print_eval_rc() {
    if [[ $1 == 0 ]]; then
        echo -e "\e[32m${2} ran succesfully\e[0m"
    else
        echo -e "\e[31m${2} failed\e[0m"
    fi
    return $1
}

trap end_script EXIT

base_dir=$(pwd)
fw_pack=$(ls T4[03xX][28xX]_V*.*.*.tar.gz | sort -V | tail -n 1)
ffmpeg_pack=$(ls Codensity_T4[03xX][28xX]_Software_Release_V*.*.*.tar.gz | sort -V | tail -n 1)

export LD_LIBRARY_PATH=/usr/local/lib/
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/

echo "Welcome to the NETINT t4xx_quick_installer utility"
echo "Please put the FW and FFmpeg release package you wish to install in the same directory as this script"
echo -e "The latest FW release package found here is:     \e[33m${fw_pack}\e[0m"
echo -e "The latest FFmpeg release package found here is: \e[33m${ffmpeg_pack}\e[0m"
if [[ $(echo ${fw_pack} | grep -Poh "(?<=T4[03xX][28xX]_V)\w\.\w\.\w.*(?=.tar.gz)") != $(echo ${ffmpeg_pack} | grep -Poh "(?<=Codensity_T4[03xX][28xX]_Software_Release_V)\w\.\w\.\w.*(?=.tar.gz)") ]]; then
    echo -e "\e[31mWARNING\e[0m: FW and SW versions do not match each other"
fi
read -p "Press [Y/y] to confirm the use of these two release packages. " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please remove release package files you do not wish to use and try again."
    end_script
fi

# Extract SW release package for auto discovery of FFmpeg versions
echo "Removing old './release/' folder..."
sudo rm -rf release
echo "Extracting new FW & SW release folders"
tar -zxf $ffmpeg_pack
tar -zxf $fw_pack

options=("Setup Environment variables"
         "Unlock CPU governor"
         "Install prerequisite Linux packages (CentOS)"
         "Install prerequisite Linux packages (Ubuntu)"
         "Install NVMe CLI"
         "Install Libxcoder")

for ff_patch in release/FFmpeg-*_t4xx_patch; do
    ver_num=$(echo ${ff_patch} | grep -Poh 'release/FFmpeg-\K[^_]*(?=_t4xx_patch)')
    if [[ $ver_num == '*' ]]; then
        continue;
    fi
    options+=("Install FFmpeg-${ver_num}")
done

options+=("Firmware Update"
          "Quit")

# Main menu loop
COLUMNS=20
while true; do
    cd $base_dir
    echo -e "\e[33mChoose an option:\e[0m"
    select opt in "${options[@]}"; do
        case $opt in
            "Setup Environment variables")
                echo -e "\e[33mYou chose $REPLY which is $opt\e[0m"

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
            "Unlock CPU governor")
                echo -e "\e[33mYou chose $REPLY which is $opt\e[0m"
                grep -qxF 'for (( i=0; i<`nproc`; i++ )); do sudo sh -c "echo performance > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor"; done 2> /dev/null' ~/.bashrc ||
                echo 'for (( i=0; i<`nproc`; i++ )); do sudo sh -c "echo performance > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor"; done 2> /dev/null' >> ~/.bashrc
                print_eval_rc $? "${opt}"
                break
            ;;
            "Install prerequisite Linux packages (CentOS)")
                echo -e "\e[33mYou chose $REPLY which is $opt\e[0m"
                sudo yum --enablerepo=extras install -y epel-release &&
                sudo yum install -y pkgconfig git redhat-lsb-core make gcc &&
                # sudo yum install -y yasm
                install_yasm
                print_eval_rc $? "${opt}"
                break
            ;;
            "Install prerequisite Linux packages (Ubuntu)")
                echo -e "\e[33mYou chose $REPLY which is $opt\e[0m"
                sudo apt-get install -y pkg-config git gcc &&
                # sudo apt-get install -y yasm
                install_yasm
                print_eval_rc $? "${opt}"
                break
            ;;
            "Install NVMe CLI")
                echo -e "\e[33mYou chose $REPLY which is $opt\e[0m"
                git clone -b v1.6 --depth=1 https://gitee.com/mirrors/nvme-cli.git &&
                cd nvme-cli*/ && sudo make && sudo make install && cd ..
                print_eval_rc $? "${opt}"
                break
            ;;
            "Install Libxcoder")
                echo -e "\e[33mYou chose $REPLY which is $opt\e[0m"
                install_libxcoder
                print_eval_rc $? "Libxcoder installation"
                break
            ;;
            Install\ FFmpeg-*)
                echo -e "\e[33mYou chose $REPLY which is $opt\e[0m"
                # get FFmpeg version# from $opt
                ver_num=$(echo ${opt} | grep -Poh 'Install FFmpeg-\K.*')
                install_ffmpeg_ver $ver_num
                print_eval_rc $? "FFmpeg installation"
                break
            ;;
            "Firmware Update")
                echo -e "\e[33mYou chose $REPLY which is $opt\e[0m"
                sudo tar -zxf $fw_pack
                cd ${fw_pack%.tar.gz} && sudo ./t4xx_auto_upgrade.sh &&
                cd .. &&
                echo "re"
                print_eval_rc $? "${opt}"
                break
            ;;
            "Quit")
                exit
            ;;
            *) echo -e "\e[31\Invalid choice!\e[0m"
            ;;
        esac
    done
done

