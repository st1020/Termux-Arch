#!/data/data/com.termux/files/usr/bin/bash
termux-setup-storage

#检测架构
case $(uname -m) in
aarch64)
  archtype="arm64"
  ;;
arm64)
  archtype="arm64"
  ;;
armv8a)
  archtype="arm64"
  ;;
arm)
  archtype="armhf"
  ;;
armv7l)
  archtype="armhf"
  ;;
armhf)
  archtype="armhf"
  ;;
armel)
  archtype="armel"
  ;;
amd64)
  archtype="amd64"
  ;;
x86_64)
  archtype="amd64"
  ;;
*)
  echo "不支持的架构 $(uname -m)"
  exit 1
  ;;
esac

#安装必要依赖
dependencies=""
if [ ! -e $PREFIX/bin/proot ]; then
  dependencies="${dependencies} proot"
fi

if [ ! -e $PREFIX/bin/pkill ]; then
  dependencies="${dependencies} procps"
fi

if [ ! -e $PREFIX/bin/pv ]; then
  dependencies="${dependencies} pv"
fi

if [ ! -e $PREFIX/bin/wget ]; then
  dependencies="${dependencies} wget"
fi

if [ ! -e $PREFIX/bin/curl ]; then
  dependencies="${dependencies} curl"
fi

if [ ! -e $PREFIX/bin/aria2c ]; then
  dependencies="${dependencies} aria2"
fi

if [ ! -z "$dependencies" ]; then
  echo "正在安装相关依赖..."
  apt install -y ${dependencies}
fi

#创建必要文件夹，防止挂载失败
mkdir -p ~/storage/external-1
ArchFolder=Arch_${archtype}

echo "检测到您当前的架构为${archtype} ，Arch Linux系统将安装至~/${ArchFolder}"

cd ~
mkdir -p ~/${ArchFolder}
ArchTarXz="arch-rootfs.tar.xz"

if [ ! -f ${ArchTarXz} ]; then
  echo "正在从清华大学开源镜像站下载ArchLinux容器镜像"
  curl -L "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/archlinux/current/${archtype}/default/" -o get-date-tmp.html >/dev/null 2>&1
  ttime=$(cat get-date-tmp.html | tail -n2 | head -n1 | cut -d\" -f4)
  rm -f get-date-tmp.html
  aria2c -x 16 -k 1M --split 16 -o $ArchTarXz "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/archlinux/current/${archtype}/default/${ttime}rootfs.tar.xz"
fi

cd ~/${ArchFolder}
echo "正在解压arch-rootfs.tar.xz"
pv ~/${ArchTarXz} | proot --link2symlink tar -pJx
cd ~

echo "正在创建proot启动脚本/data/data/com.termux/files/usr/bin/arch "
#此处EndOfFile不要加单引号
cat >/data/data/com.termux/files/usr/bin/arch <<-EndOfFile
#!/data/data/com.termux/files/usr/bin/bash
cd ~
startarch(){
	unset LD_PRELOAD
	command="proot"
	command+=" --link2symlink"
	command+=" -0"
	command+=" -r ${ArchFolder}"
	command+=" -b /dev"
	command+=" -b /proc"
	command+=" -b ${ArchFolder}/root:/dev/shm"
	#您可以在此处修改挂载目录
	command+=" -b /sdcard:/root/sd"
	command+=" -b /data/data/com.termux/files/home/storage/external-1:/root/tf"
	command+=" -b /data/data/com.termux/files/home:/root/termux"
	command+=" -w /root"
	command+=" /usr/bin/env -i"
	command+=" HOME=/root"
	command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
	command+=" TERM=\$TERM"
	command+=" LANG=zh_CN.UTF-8"
	com="\$@"
	if [ -f ~/${ArchFolder}/bin/zsh ];then
		command+=" /bin/zsh --login"
	else
		command+=" /bin/bash --login"
	fi
	exec \$command
}

if [ \$# == 0 ];then
	startarch
elif [ \$1 == "rm" ]; then
	chmod 777 -R $ArchFolder
	rm -rf $ArchFolder $PREFIX/bin/arch 2>/dev/null || tsudo rm -rf $ArchFolder $PREFIX/bin/arch
	sed -i '/alias arch=/d' $PREFIX/etc/profile
	source profile >/dev/null 2>&1
	echo '移除完成，如需卸载aria2，请手动输apt remove aria2'
	echo '若需要重装，则不建议移除镜像文件。'
	while true
	do
		read -p "是否需要删除镜像文件？ [Y/n] " input
		case \$input in
			[yY][eE][sS]|[yY])
				rm -f ~/${ArchTarXz}
				echo "已删除镜像"
				break;;
			[nN][oO]|[nN])
				break;;
			*)
				echo "输入错误，请重新输入...";;
		esac
	done
elif [ \$1 == "vnc" ] ;then
	am start -n com.realvnc.viewer.android/com.realvnc.viewer.android.app.ConnectionChooserActivity
	touch ~/${ArchFolder}/root/.vnc/startvnc
	startarch
elif [ \$1 == "stopvnc" ] ;then
	pkill -u \$(whoami)
elif [ \$1 == "help" ] ;then
	echo -e "arch - 启动Arch Linux\narch vnc - 启动Arch Linux并启动VNC服务\narch stopvnc - 关闭VNC服务\narch rm - 删除Arch Linux"
else
	echo "参数错误"
fi
EndOfFile

if [ ! -L '/data/data/com.termux/files/home/storage/external-1' ]; then
  sed -i 's@^command+=" -b /data/data/com.termux/files/home/storage/external-1@#&@g' /data/data/com.termux/files/usr/bin/arch
fi

chmod +x /data/data/com.termux/files/usr/bin/arch
alias arch="/data/data/com.termux/files/usr/bin/arch"

echo "您可以输rm ~/${ArchTarXz}来删除容器镜像文件"
ls -lh ~/${ArchTarXz}

cd ~/${ArchFolder}/root

#将初次启动执行的命令写入~/.profile
cat > .profile <<-'EDITBASHRC'
#!/bin/bash
choose(){
	while true
	do
		read -p "$1 [Y/n] " input
		case $input in
			[yY][eE][sS]|[yY])
				return 1
				break;;
			[nN][oO]|[nN])
				return 2
				break;;
			*)
				echo "输入错误，请重新输入...";;
		esac
	done
}

echo "您已成功安装Arch Linux，之后可以在Termux中输入arch命令来进入Arch Linux系统。"

echo "正在配置网络..."
#配置dns解析
#Arch容器镜像中resolv.conf是软连接，需要先删除才能建立
rm -rf /etc/resolv.conf
cat > /etc/resolv.conf <<-'EndOfFile'
nameserver 114.114.114.114
nameserver 240c::6666
EndOfFile

echo "接下来，系统将询问您是否要导入密钥，请输入y并回车"
sleep 3
#配置清华源
sed -i -e '1i Server = http://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/$arch/$repo' /etc/pacman.d/mirrorlist
#配置ArchLinuxcn清华源
echo -e '[archlinuxcn]\nSigLevel = Optional TrustAll\nServer = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch' >> /etc/pacman.conf
pacman -Sy
pacman -Sq --noconfirm archlinuxcn-keyring
#删除archlinuxcn的下一行
sed -i '/archlinuxcn/{n;d}' /etc/pacman.conf
pacman -Sy

#配置中文环境
echo "正在配置中文环境..."
sed -i 's/#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen
echo -e "LANG=zh_CN.UTF-8\nLANGUAGE=zh_CN:zh:en_US" > /etc/locale.conf
locale-gen
#Arch自带了man，无需再次安装，仅安装中文语言包
pacman -Sq --noconfirm man-pages-zh_cn

#配置国内时区
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo  "正在升级所有软件包..."
pacman -Syu --noconfirm

sleep 1

#配置pacman
choose "是否要更改pacman为彩色输出？"
if [ $? == 1 ]; then
	sed -i 's/#Color/Color/g' /etc/pacman.conf
	echo "设置完成"
fi

choose "是否要在使用pacman升级软件包前对比版本？"
if [ $? == 1 ]; then
	sed -i 's/#VerbosePkgLists/VerbosePkgLists/g' /etc/pacman.conf
	echo "设置完成"
fi


choose "是否要安装yay（AUR helper/Pacman wrapper）？"
if [ $? == 1 ]; then
	cd ~
	echo "正在安装依赖..."
	pacman -Sq --needed --noconfirm base-devel git go
	echo "正在从AUR克隆yay..."
	git clone https://aur.archlinux.org/yay.git
	cd yay
	echo "正在构建yay..."
	#makepkg工具不允许使用root权限编译软件包，需要先启用nobody账户
	#makepkg使用的fakeroot不支持aarch64架构，需要先卸载再安装fakeroot-tcp
	#在nobody账户下没有权限安装软件包，故仅构建，但不安装
	pacman -Rn --noconfirm fakeroot
	pacman -Sq --noconfirm fakeroot-tcp
	sed -i 's@nobody:x:65534:65534:Nobody:/:/usr/bin/nologin@nobody:x:65534:65534:Nobody:/:/bin/bash@g' /etc/passwd
	su nobody -c "makepkg"
	echo "正在安装yay..."
	pacman -U --noconfirm $(ls yay*.pkg.tar.*)
	echo "正在更换AUR源到清华源..."
	yay --aururl "https://aur.tuna.tsinghua.edu.cn" --save
	echo "yay安装完成"
fi

choose "是否要安装Powerpill（Pacman wrapper/使用Aria2同时下载多个软件包）？"
if [ $? == 1 ]; then
	pacman -Sq --noconfirm powerpill
fi

echo -e "请选择pacman的下载程序：\n"
echo -e "  1 默认   2 wget   3 curl   4 aria2\n"
echo "如果您已经安装了Powerpill，则没有必要再更改pacman的下载程序，在Pacman的XferCommand使用 aria2c 不会导致并行下载多个包。因为Pacman调用XferCommand时是一次一个包调用的，等待下载完成才会启动下一个。想要并行下载多个包，请使用Powerpill。"
read -p '请输入序号：' OPTION;
if [ "${OPTION}" == '2' ]; then
	pacman -Sq --noconfirm wget
	sed -i 's/#XferCommand = \/usr\/bin\/wget/XferCommand = \/usr\/bin\/wget/g' /etc/pacman.conf
	echo "设置完成"
elif [ "${OPTION}" == '3' ]; then
	pacman -Sq --noconfirm curl
	sed -i 's/#XferCommand = \/usr\/bin\/curl/XferCommand = \/usr\/bin\/curl/g' /etc/pacman.conf
	echo "设置完成"
elif [ "${OPTION}" == '4' ]; then
	pacman -Sq --noconfirm aria2
	sed -i '20i XferCommand = /usr/bin/aria2c --allow-overwrite=true -c --file-allocation=none --log-level=error -m2 --max-connection-per-server=2 --max-file-not-found=5 --min-split-size=5M --no-conf --remote-time=true --summary-interval=60 -t5 -d / -o %o %u' /etc/pacman.conf
	echo "设置完成"
else
	echo "保留默认"
fi

choose "是否要添加Arch4edu（面向高校用户的非官方软件仓库）？"
if [ $? == 1 ]; then
	pacman-key --recv-keys 7931B6D628C8D3BA
	pacman-key --finger 7931B6D628C8D3BA
	pacman-key --lsign-key 7931B6D628C8D3BA
	echo -e '[arch4edu]\nServer = https://mirrors.tuna.tsinghua.edu.cn/arch4edu/$arch' >> /etc/pacman.conf
	pacman -Sy
	echo "设置完成"
fi

choose "是否要安装Zsh？"
if [ $? == 1 ]; then
	pacman -Sq --noconfirm zsh
	chsh -s /usr/bin/zsh
	choose "是否要安装Oh My Zsh？"
	if [ $? == 1 ]; then
		pacman -Sq --noconfirm oh-my-zsh-git
		cp /usr/share/oh-my-zsh/zshrc ~/.zshrc
	fi
	echo "请注意：接下来可选安装的插件在安装时均没有配置为由Oh My Zsh管理，安装以下插件并不需要安装Oh My Zsh，如果您要安装Oh My Zsh的插件，请手动配置。"
	echo "请注意：配置过多的插件可能会导致Zsh运行缓慢。"
	choose "是否要安装Zsh语法高亮插件（zsh-syntax-highlighting）？"
	if [ $? == 1 ]; then
		pacman -Sq --noconfirm zsh-syntax-highlighting
		echo "source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
	fi
	choose "是否要安装Zsh自动建议插件（zsh-autosuggestions）？"
	if [ $? == 1 ]; then
		pacman -Sq --noconfirm zsh-autosuggestions
		echo "source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
	fi
	choose "是否要安装Zsh历史查询插件（zsh-history-substring-search）？"
	if [ $? == 1 ]; then
		pacman -Sq --noconfirm zsh-history-substring-search
		echo "source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" >> ~/.zshrc
	fi
	if [ ! -e ~/.zshrc ]; then
		touch ~/.zshrc
	fi
	echo "arch boot" >> ~/.zshrc
fi

#配置用户自定义选项
read -p "请设置您的主机名（直接回车保持默认）：" hostname
if [ ! -z $hostname ]; then
	echo "$hostname" > /etc/hostname
	#注意双引号解析变量
	sed -i "s/LXC_NAME/$hostname/g" /etc/hosts
	echo "配置完成"
fi

#因涉及下面的桌面环境安装问题，故放弃
#choose "使用root账户工作可能不够安全，您是否要新建一个低权限用户？"
#if [ $? == 1 ]; then
#	echo "请设定root密码"
#	passwd
#	read -p "请设定新用户名：" username
#	if [ -e "/usr/bin/zsh" ]; then
#		useradd -m -g users -G wheel -s /usr/bin/zsh "$username"
#	else
#		useradd -m -g users -G wheel -s /bin/bash "$username"
#	fi
#	choose "您是否要为新用户（$username）设置密码？"
#	if [ $? == 1 ]; then
#		echo "请设定新用户（$username）的密码"
#		passwd $username
#	fi
#	echo "配置完成"
#fi

echo "正在创建管理脚本..."

mkdir -p /usr/local/bin

#创建Arch内部的管理脚本
cat > /usr/local/bin/arch <<-'EndOfFile'
#!/bin/bash
main(){
	echo -e "     Arch Linux for Termux管理工具\n\n"
	echo -e "   1   启动VNC服务\n"
	echo -e "   2   停止VNC服务\n"
	echo -e "   3   安装Xfce桌面环境\n"
	echo -e "   4   安装LXQt桌面环境\n"
	echo -e "   5   安装LXDE桌面环境\n"
	echo -e "   6   安装i3窗口管理器\n"
	echo -e "   7   配置OpenBox窗口管理器\n"
	echo -e "   8   卸载图形界面\n"
	echo -e "   0   退出\n"
	read -p '请输入序号：' OPTION;
	if [ "${OPTION}" == '1' ]; then
		startvnc
	elif [ "${OPTION}" == '2' ]; then
		stopvnc
	elif [ "${OPTION}" == '3' ]; then
		install xfce4 startxfce4
	elif [ "${OPTION}" == '4' ]; then
		install lxqt startlxqt
	elif [ "${OPTION}" == '5' ]; then
		install lxde startlxde
	elif [ "${OPTION}" == '6' ]; then
		echo "i3只是窗口管理器，需要您自行配置和安装其他必须的软件"
		echo "在安装后，如不进行配置，将仅显示一个黑屏，若屏幕最底部有状态栏，证明安装成功"
		read -p "请按任意键继续..." input
		install i3 i3
	elif [ "${OPTION}" == '7' ]; then
		echo "OpenBox只是窗口管理器，需要您自行配置和安装其他必须的软件"
		echo "在安装后，如不进行配置，将仅显示一个黑屏，单击鼠标右键（两指点击屏幕）确认有菜单出现，证明安装成功"
		read -p "请按任意键继续..." input
		pacman -Sq --noconfirm openbox
		mkdir -p ~/.config/openbox
		cp -a /etc/xdg/openbox/. ~/.config/openbox/
		install openbox openbox-session
	elif [ "${OPTION}" == '8' ]; then
		read -p "请输入要卸载的桌面环境（如xfce）：" remove
		remove $remove
	elif [ "${OPTION}" == '0' ]; then
		exit
	else
		echo "输入错误！"
	fi
	read -p "请按任意键继续..." -n 1 press
	main
}

startvnc(){
	stopvnc
	export USER=root
	export HOME=/root
	vncserver -geometry 720x1440 -depth 24 -name remote-desktop :1
	echo "正在启动vnc服务,本机默认vnc地址localhost:5901"
	#下面那条命令不要加双引号
	echo 局域网地址 $(ip -4 -br -c a |tail -n 1 |cut -d '/' -f 1 |cut -d 'P' -f 2):5901
}

stopvnc(){
	export USER=root
	export HOME=/root
	vncserver -kill :1
	pkill Xvnc
	rm -rf /tmp/.X1*
}

install(){
echo "即将为您安装思源黑体(中文字体)、tigervnc和$1。"
pacman -Sq --noconfirm --needed noto-fonts-cjk tigervnc $1

#环境变量DISPLAY
grep 'export DISPLAY' /etc/profile ||echo "export DISPLAY=:1" >> /etc/profile

#创建xstartup文件
mkdir -p ~/.vnc
cat > ~/.vnc/xstartup <<-EOF
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch $2
EOF
chmod +x ~/.vnc/xstartup

echo '即将为您启动vnc服务，您需要输两遍（不可见的）密码。'
echo '如果提示view-only，那么建议您输n，选择权在您自己的手上。'
echo '请输入6至8位密码'
startvnc
echo '您之后可以在Arch Linux或者Termux中输入 arch vnc 启动vnc服务，输入 arch stopvnc 停止'
}

remove(){
	if [ ! -z $2 ];then
		echo "请输入要卸载的桌面环境！如 arch install xfce"
	elif [ $2 == "xfce" ]; then
		pacman -Rn --noconfirm noto-fonts-cjk tigervnc xfce4
	elif [ $2 == "lxqt" ]; then
		pacman -Rn --noconfirm noto-fonts-cjk tigervnc lxqt
	elif [ $2 == "lxde" ]; then
		pacman -Rn --noconfirm noto-fonts-cjk tigervnc lxde
	elif [ $2 == "i3" ]; then
		pacman -Rn --noconfirm noto-fonts-cjk tigervnc i3
	elif [ $2 == "openbox" ]; then
		pacman -Rn --noconfirm noto-fonts-cjk tigervnc openbox
		rm -rf ~/.config/openbox
	else
		echo "不支持自动卸载您选择的桌面环境！"
	fi
}

if [ $# == 0 ];then
	main
elif [ $1 == "boot" ] ;then
	if [ -f "/root/.vnc/startvnc" ]; then
		rm -f /root/.vnc/startvnc
		startvnc
		echo "已为您启动vnc服务"
	fi
elif [ $1 == "install" ]; then
	if [ -z $2 ];then
		echo "请输入要安装的桌面环境！如 arch install xfce"
	elif [ $2 == "xfce" ]; then
		install xfce4 startxfce4
	elif [ $2 == "lxqt" ]; then
		install lxqt startlxqt
	elif [ $2 == "lxde" ]; then
		install lxde startlxde
	elif [ $2 == "i3" ]; then
		echo "i3只是窗口管理器，需要您自行配置和安装其他必须的软件"
		echo "在安装后，如不进行配置，将仅显示一个黑屏，若屏幕最底部有状态栏，证明安装成功"
		read -p "请按任意键继续..." input
		install i3 i3
	elif [ $2 == "openbox" ]; then
		echo "OpenBox只是窗口管理器，需要您自行配置和安装其他必须的软件"
		echo "在安装后，如不进行配置，将仅显示一个黑屏，单击鼠标右键（两指点击屏幕）确认有菜单出现，证明安装成功"
		read -p "请按任意键继续..." input
		pacman -Sq --noconfirm openbox
		mkdir -p ~/.config/openbox
		cp -a /etc/xdg/openbox/. ~/.config/openbox/
		install openbox openbox-session
	else
		echo "不支持自动安装您选择的桌面环境！"
	fi
elif [ $1 == "remove" ]; then
	remove $2
elif [ $1 == "vnc" ]; then
	startvnc
elif [ $1 == "stopvnc" ]; then
	stopvnc
elif [ $1 == "help" ]; then
	echo -e "arch - 打开管理菜单\narch vnc - 启动VNC服务\narch stopvnc - 停止VNC服务\narch install (桌面环境) - 安装选择的桌面环境\narch remove (桌面环境) - 卸载选择的桌面环境"
else
	echo "参数错误！"
fi
EndOfFile

chmod +x /usr/local/bin/arch

echo "arch boot" > ~/.profile

echo "Welcome to Arch Linux."
cat /etc/issue
uname -a
cd ~

echo "配置完成！5秒后进入GUI配置..."
sleep 5
/usr/local/bin/arch
EDITBASHRC

/data/data/com.termux/files/usr/bin/arch
