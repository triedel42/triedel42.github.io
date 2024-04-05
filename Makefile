SRCS = $(wildcard *.md)
HTML = $(SRCS:.md=.html)

PD_METADATA = --metadata=title:"triedel's 42 Notebook" --metadata=subtitle:"\"Mostly useless\""
PD = pandoc --standalone --template=template.html --css=styling.css $(PD_METADATA)

OS = $(shell uname -s)

all: $(HTML)

index.html: index.md
	$(PD) -o $@ $<

%.html: %.md
	$(PD) --toc -o $@ $<

open: all
ifeq ($(OS),Darwin)
	open index.html
else
	firefox index.html
endif

setup:
ifeq ($(OS),Linux)
	sudo apt-get install -y pandoc
endif
ifeq ($(OS),Darwin)
	brew install pandoc
endif

clean:
	rm -f $(HTML)
fclean: clean

re: clean
	$(MAKE) all

.PHONY: open setup clean re
