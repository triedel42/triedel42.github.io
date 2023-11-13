# Tips and tricks

## Installing packages
Homebrew can be [installed without root][brew_noroot], allowing you to install [packages][brew_formulae] with `brew install <package>`

## Write your own tests!
You *will* find mistakes. I use [GoogleTest][gtest] for this, becausee it gives me pretty output without any work. With GoogleTest a simple test case looks like this.
```c
#include <gtest/gtest.h>

extern "C" {
	#include "libft.h"
}

TEST(Libft, ft_isalpha)
{
	EXPECT_EQ(ft_isalpha('a'), 1);
	EXPECT_EQ(ft_isalpha('0'), 0);
}

int	main(void)
{
	testing::InitGoogleTest();
	return (RUN_ALL_TESTS());
}
```
To compile it you need the `googletest` package. After that we can use these make rules to compile and run the test with `make test`.
```makefile
$(TEST): gtest.cc $(NAME)
	$(CXX) $(CFLAGS) $(shell pkg-config --cflags gtest) -o $@ $^ \
			$(shell pkg-config --libs gtest)

test: $(TEST)
	clear
	./$(TEST)
```

## make -j
You can compile much faster if you allow make to build in parallel. Put this in your `~/.zshrc`
```
export MAKEFLAGS=-j8
```

[brew_noroot]:		https://docs.brew.sh/Installation#untar-anywhere-unsupported
[brew_formulae]:	https://formulae.brew.sh/
[gtest]:			https://google.github.io/googletest/