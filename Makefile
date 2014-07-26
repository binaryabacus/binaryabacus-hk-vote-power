stylus = node_modules/.bin/stylus
coffee = node_modules/.bin/coffee
jade = node_modules/.bin/jade

all: main.css main3.js

main.css: main.styl
	$(stylus) < $< > $@

main2.js: main2.coffee
	$(coffee) -c $<

main3.js: main3.coffee
	$(coffee) -m -c $<

clean:
	rm main.css main1.js main2.js main3.js

.PHONY: all clean
