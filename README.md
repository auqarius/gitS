# gitSkills List

## OverView

**This is my git learn command list.
**

* $ git init // cd到需要git的目录，然后init，就可以把这个目录变成git可以管理的仓库。
* $ git add README.md // 把工作区修改过的README.me文件提交到暂存区
* $ git commit -m "description" // 把暂存区的改动提交到本地仓库
* $ git status //查看git状态，是不是有没有提交的
* $ git diff README.md // 查看README.md 文件被修改了什么
* $ git log // 查看提交历史
* $ git log --pretty=oneline // 查看简化提交历史
* $ git reset --hard HEAD^ // 回退到上一个版本,HEAD指的是这个版本，^指上一个，^^指上上一个
* $ git reset --hard 36d2s3 // 回退到某个特定的版本
* $ git reflog // 输入git历史命令
* $ git checkout -- README.md // 让文件回到最近一次git commit 或git add 的状态
* $ git reset HEAD README.md // 把暂存区的修改退回到工作区，相当于撤销git add
* $ 