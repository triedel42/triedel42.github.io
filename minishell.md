# Minishell

## Resources
- [The Bourne-Again Shell][aosa-bash] gives a great overview for our tasks
- [The Shell Command Language][posix-shell-lang] (Part of the [POSIX standard][posix])
- The Open Group has a [Shell and Utilities section][posix-shell]
- [dash (sh) Source code][dash-repo]

## Preliminary research
[This page][posix-shell-lang] from the POSIX standard describes how a shell should behave to be POSIX-compliant and we will need it again and again. Even though our goal is not to write a shell that follows it.

Before writing a bunch of code, let's see how software is written. Maybe we will find some good approaches to make our life easier. In particular it will be useful to have a look at [bash][bash], [dash][dash] and [zshell][zsh]. I did a quick `cat *.c *.h | wc -l` in the source dir to see just how big these projects are already, and this doesn't even include some parts like the bash modules folder:

- [dash][dash-repo]: around 18K LOC
- [bash][bash-repo]: around 82K LOC
- [zsh][zsh-repo]: around 80K LOC

[Dash][dash] in particular will prove useful, because it is the smallest of them, and supposedly POSIX-compliant. A quick look at its [parser.c][dash-parser.c] makes it seem pretty helpful.

Reading source code without any guidance can be time-consuming. [This Chapter][aosa-bash] of the [AOSA book][aosa] (which is awesome btw.) describes the implementation of bash. That should give us a good starting point for our research. It also has this helpful graphic.

<a href="img/minishell-bash.png"><img style="width: 100%" src="img/minishell-bash.png"></img></a>

[Here][bash-op] are the steps that bash performs. As you can see they are very similar. But now we have a good idea about what's ahead of us.

[bash]:				https://www.gnu.org/software/bash/
[dash]:				http://gondor.apana.org.au/~herbert/dash/
[zsh]:				https://www.zsh.org/
[bash-repo]:		https://savannah.gnu.org/git/?group=bash
[dash-repo]:		https://git.kernel.org/pub/scm/utils/dash/dash.git/
[zsh-repo]:			https://zsh.sourceforge.io/Arc/source.html
[dash-parser.c]:	https://git.kernel.org/pub/scm/utils/dash/dash.git/tree/src/parser.c
[bash-op]:			https://www.gnu.org/software/bash/manual/html_node/Shell-Operation.html

### Formal languages
Some new concepts for parsing are [Formal languages][formal-language] and [regular grammars][reg-grammar].

Our input - if syntactically correct - can be described by such a regular grammar.

When we parse our text we transform a stream of characters into an [Abstract Syntax Tree][ast]. This abstract syntax tree is then the data structure that we can work with to execute (complex) shell commands.

I stumbled upon this demotivating line while reading about parsing:

> The Posix shell committee deserves significant credit for finally publishing a definitive grammar for a Unix shell, albeit one that has plenty of context dependencies. - [AOSA][aosa-bash]

That's right. Credit goes to the people who managed to come up with the grammar which we're supposed to implement!

I suppose that means the "shell grammar" is inconsistent and (more importantly) context-dependent. Context-dependency by the way has implications for parsing.

If we  - as we should here - want to make our life easier, we could constrain ourselves to a simplified grammar. We don't have to care about POSIX after all, we build minishell. Most importantly we need our grammar to be context-free.

[formal-language]:			https://en.wikipedia.org/wiki/Formal_language
[reg-grammar]:				https://en.wikipedia.org/wiki/Regular_grammar
[ast]:						https://en.wikipedia.org/wiki/Abstract_syntax_tree

#### Parser
I would like to build an [LL parser][llparser], because we could make it work with any arbitrary grammar. This means that our shell grammar must be context-free.

[llparser]:			https://en.wikipedia.org/wiki/LL_parser

#### Tokenizer
As a first step we divide our input into [tokens][lexical-ana]. Thankfully this process is described in detail in section "2.3 Token Recognition" [here][posix-shell-lang].



[aosa]:				https://aosabook.org
[aosa-bash]:		https://aosabook.org/en/v1/bash.html				
[posix]:			https://pubs.opengroup.org/onlinepubs/9699919799/
[posix-shell]:		https://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html
[posix-shell-lang]:	https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18
[lexical-ana]:		https://en.wikipedia.org/wiki/Lexical_analysis#Token