SITES=index.html gallery.html

all: $(SITES)

%.html: %.md
	pandoc -t html $< -o $@ --template template.html

clean:
	rm -f $(SITES)

re: clean all
