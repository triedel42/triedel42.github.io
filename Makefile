SRCS = $(wildcard *.md)
HTML = $(SRCS:.md=.html)

PD_METADATA = --metadata=title:"triedel's Guide to 42" --metadata=subtitle:"mostly useless"
PD = pandoc --standalone --template=template.html --css=styling.css $(PD_METADATA)

all: $(HTML)

index.html: index.md
	$(PD) -o $@ $<

%.html: %.md
	$(PD) --toc -o $@ $<

setup:
	sudo apt-get install -y pandoc

clean:
	rm -f $(HTML)

re: clean all

.PHONY: setup clean re
