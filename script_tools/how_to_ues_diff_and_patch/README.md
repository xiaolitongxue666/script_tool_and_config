# How to use diff and patch

## diff

diff [options] [original filename] [changed filename]

### options
 - '-N' : 忽略不存在的文件
 - '-r' : 通过目录递归地执行 diff。用于一次比较多个文件。注意：这与-R不同，后者是一个补丁选项
 - '-u' : 以更易于阅读的格式显示输出。这可能会删除一些信息，例如上下文行
 - '-y' : 强制输出并排显示差异


```bash
diff -Nur children.py parents.py > from_c_to_p.patch

diff -ruN folder1/ folder2/ > patchfile.patch
```

## patch

patch [options] [pached filename] [path filename]
patch [options] < [patch filename]

### options
 - '-b'    : 创建原始文件的备份
 - '-i'    : 强制命令从 .patch 文件而不是从标准输入读取补丁
 - '-p[#]' : 指示命令从文件路径到文件名去除#number 个斜杠。您会在我们的大多数示例中看到，我们使用 -p0 以便不删除斜线
 - '-R'    : 反转之前的补丁
 - '-s'    : 静默运行命令。如果有错误，它只会显示过程

```bash
# 将 file1.html 替换为您的原始文件。这将用 file2.html 的更改内容覆盖 file1.html 的旧内容。
patch file1.html patchfile.patchfile

# 如果你想在修补之前将文件恢复到它以前的版本，你可以通过运行这个命令来实现
patch -p0 -R -i patchfile.patch

# 给[pached filename]文件或者文件夹，打上补丁
patch -s -p0 < patchfile.patch
```

