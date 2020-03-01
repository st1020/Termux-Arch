# Termux-Arch

## 简介

这是一个帮助你在Termux上一键安装Arch Linux PRoot容器并自动配置配置中文环境的脚本。

![pictur1](https://gitee.com/st1020/Termux-Arch/raw/master/pic/1.jpg)

支持一键安装图形界面

![pictur3](https://gitee.com/st1020/Termux-Arch/raw/master/pic/2.jpg)

本项目移植自 [Moe/Termux-Debian项目](https://gitee.com/mo2/Termux-Debian) 。

支持arm64、armhf和amd64架构。

## 安装

你可以直接在Termux内输入以下命令安装Arch Linux：
```shell
pkg i -y wget && bash -c "$(wget -qO- 'https://github.com/st1020/Termux-Arch/raw/master/Arch.sh')"
```
或者：
```shell
pkg i -y wget && bash -c "$(wget -qO- 'https://gitee.com/st1020/Termux-Arch/raw/master/st.sh')"
```

## 使用

安装完成后，你可以在Termux中输入`arch`启动Arch Linux，输入`arch rm`卸载，输入`arch help`查看更多用法。

还可以在Arch Linux系统中输入`arch`打开管理器，输入`arch help`查看更多用法。

## 更新日志

**v1.0 2020.3.1**

第一次更新。

## 开源许可

本脚本有st1020移植自 [Moe/Termux-Debian项目](https://gitee.com/mo2/Termux-Debian)。 

本脚本根据GNU General Public License, version 3 (GPL-3.0)开放源代码。
