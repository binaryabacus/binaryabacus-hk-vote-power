stylus = node_modules/.bin/stylus
coffee = node_modules/.bin/coffee
jade = node_modules/.bin/jade

all: main.css main2.js

main.css: main.styl
	$(stylus) < $< > $@

main2.js: main2.coffee
	$(coffee) -c $<

clean:
	rm main.css main2.js

.PHONY: all clean
