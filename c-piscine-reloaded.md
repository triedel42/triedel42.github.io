# piscine-reloaded
> “Time is an illusion. Lunchtime doubly so.” - HG2G

Welcome back! Let’s find out just how bad our memory is. Mine has more leaks than my code, so here’s where to look up what has seeped out.

## ex00: `ls -l`
- [`man ls`][1], mainly the section titled `The Long Format`.
- To change the permissions we use [chmod][2].<br>
  There are 2 types of syntax: symbolic mode (e.g. `chmod u+x test1`) and absolute mode (e.g. `chmod 715 test0`)
- To modify the access time we need [touch][3] with the flags `-t` and sometimes `-h`
- Also important here is the [difference between a hard link and a soft link][4].
- We can also learn about [tar][5], which creates archives similar to .zip files.<br>
  The basic usage is `tar -cf <archive> <contents>` to create, `tar -xf <archive>` to unpack and `tar -tf <archive>` to list the contents.

## ex01: echo, cat and writing to file
- There are many ways to create the file.
  - [`echo`][23] together with [output redirection][10]
  - [`cat`][22]
  - any editor (like `vim` or `nano`)
- One way to view the exact contents of a file - byte for byte - is the command [`xxd`][20] (or [`hexdump`][21]).
```
$ xxd z
00000000: 5a0a                                     Z.
```
- Do you remember that they always did this ` | cat -e` when testing our output? We can also use this here to make sure there is a `$` marking the line break at the end.

## ex02: find
- [`man find`][30]
- The simplest way to use find for listing files is something like `find . -type f`. We can use `-name` to filter by file name (`find . -name '*.txt'`). But to accomplish what we need here, we need to use `-o` ("or") for combining those name filters. However we have to surround this expression with brackets. And we have to "escape" those brackets using backslashes `\`, such that our shell passes them on to `find` and doesn't interpret them as something else.

## ex03: Parameter expansion
- I believe the real reference to a solution here is [The shell manual][31] (search for '%'). But frankly most of these seem to be rather obscure shell features.
- Suffice it to say that `${VAR%.*}` removes the extension from a file name, if `$VAR` was set to that name before. We can combine this with our new best friend `find` to reach our goal.

## ex04: ifconfig, grep
- [`ifconfig`][40] gives us the entire list of network adapters, a pretty large output. Luckily we have [`grep`][41], which filters out lines that contain a specific string.
- What we can get with those two commands still isn't quite enough. We have to trim that line down a big. I used [`cut`][42] for that.

# Review Questions
- What does `ls -l` do? Where can I find out?
- What's the difference between a soft link (`ln -s`) - aka symbolic link - and a hard link (`ln`)?
- What does the following output mean? What is the meaning of each column?
```
$ ls -l
total 32
drwx--xr-x 2 triedel triedel 4096 Jun  1 20:47 test0
-rwx--xr-- 1 triedel triedel    4 Jun  1 21:46 test1
dr-x---r-- 2 triedel triedel 4096 Jun  1 22:45 test2
-r-----r-- 2 triedel triedel    1 Jun  1 23:44 test3
-rw-r----x 1 triedel triedel    2 Jun  1 23:43 test4
-r-----r-- 2 triedel triedel    1 Jun  1 23:44 test5
lrwxrwxrwx 1 triedel triedel    5 Jun  1 22:20 test6 -> test0
```
- When you extract your archive the permissions change. How do you prevent that? Why do they change? (hint: umask)
- Why does `touch -t 06012220 test6` not do what one might expect? Which flag prevents it?
- What is a "dangling soft link". Is there such a thing as a "dangling hard link"? Why?
<hr id="ex01">
- How can we dump the contents of a file?
- How do we tell `echo` to not end with a line break?
<hr id="ex02">
- How do we use find to list all files here and in subfolders?
- How do we combine multiple expressions?
- How do we negate them (find everything that's not a `.c` file for example)
- How can we run a command on each file?
- Let's write a find command that recursively tells us the file type (so runs `file`)
<hr id="ex03">
- In the shell, how do we remove the file extension from a filename?
- Can we also remove patterns from the beginning of a variable? How? What is the syntax?
<hr id="ex04">

[1]: https://man.freebsd.org/cgi/man.cgi?ls
[2]: https://man.freebsd.org/cgi/man.cgi?chmod
[2]: https://man.freebsd.org/cgi/man.cgi?chmod
[3]: https://man.freebsd.org/cgi/man.cgi?touch
[4]: https://www.redhat.com/sysadmin/linking-linux-explained
[5]: https://man.freebsd.org/cgi/man.cgi?tar

[10]: https://www.gnu.org/software/bash/manual/html_node/Redirections.html

[20]: https://man.freebsd.org/cgi/man.cgi?xxd
[21]: https://man.freebsd.org/cgi/man.cgi?hexdump
[22]: https://man.freebsd.org/cgi/man.cgi?cat
[23]: https://man.freebsd.org/cgi/man.cgi?echo
[30]: https://man.freebsd.org/cgi/man.cgi?find
[31]: https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
[40]: https://man.freebsd.org/cgi/man.cgi?ifconfig
[41]: https://man.freebsd.org/cgi/man.cgi?grep
[42]: https://man.freebsd.org/cgi/man.cgi?cut
