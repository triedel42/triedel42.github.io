# [Libft][intra-libft]
> "Look," said Arthur, "would it save you a lot of time if I just gave up and went mad now?"

Some of the mandatory functions are *not* part of the C standard library. They are however available on MacOS, which adopts them from BSD. I refer to [FreeBSD's man pages][freebsd] (same as `man`) for those instead of the [C reference][cref].

## Mandatory part
Most of the functions concern either chars or strings. The other three are taken from [`stdlib.h`][stdlib_h].

### Char functions
The [reference][ctype_h] has a handy table that gives a good overview. The man pages contains the same info.

- [ctype.h][ctype_h]: `isalpha, isdigit, isalnum, isprint, toupper, tolower`
- BSD libc: `isascii`

### String functions
- [string.h][string_h]: `strlen, memset, memcpy, memmove, strchr, strrchr, memchr, memcmp`
- BSD libc: `bzero, strlcpy, strlcat, strncmp, strnstr`

### Others
- [stdlib.h][stdlib_h]: `atoi, calloc`
- BSD libc: `strdup`

## Mandatory part - Part 2 (Additional functions)
Like the subject says there is no man page here. They are all functions for strings:

`ft_substr, ft_strjoin, ft_strtrim, ft_split, ft_itoa, ft_strmapi, ft_striteri, ft_putchar_fd, ft_putstr_fd, ft_putendl_fd, ft_putnbr_fd`

## Bonus part
Here we are building a [singly linked list][wiki_ll].

## Remarks
- I struggled with strlcat, because the return value that it gives seems to contradict the man page in some cases. For those cases I actually condone having a peek at [bsd_libc][the original code] to understand how it's supposed to behave. I noticed that we always count to the back of `src` and up to len in `dst`. That helped me reproduce the same behavior.

# Resources
- [ctype.h][ctype_h]
- [string.h][string_h]
- [stdlib.h][stdlib_h]
- [FreeBSD man pages][freebsd]

[intra-libft]:		https://projects.intra.42.fr/projects/42cursus-libft
[cref]:             https://cplusplus.com/reference/clibrary/
[freebsd]:          https://man.freebsd.org/cgi/man.cgi
[string_h]:         https://cplusplus.com/reference/cstring/
[ctype_h]:          https://cplusplus.com/reference/cctype/
[stdlib_h]:         https://cplusplus.com/reference/cstdlib/
[wiki_ll]:          https://en.wikipedia.org/wiki/Linked_list
[bsd_libc]:			https://cgit.freebsd.org/src/tree/lib/libc/string
