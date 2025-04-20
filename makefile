.PHONY: help
help: makefile
	@tail -n +4 makefile | grep ".PHONY"


.PHONY: build
build:
	npx cake build


.PHONY: start
start:
	npx cake start


.PHONY: link-hooks
link-hooks:
	npx cake linkHooks


.PHONY: check-style
check-style:
	npx coffeelint Cakefile .


.PHONY: api-docs
api-docs:
	npx crojsdoc -o apidoc src/**/*.coffee


.PHONY: docs
docs:
	npx groc


.PHONY: test
test: check-style
	npx mocha --compilers coffee:coffee-script/register --recursive


.PHONY: test-client
test-client:
	npx karma start


.PHONY: prepublish
prepublish:
	npm test && npm run check-style


.PHONY: clean
clean:
	npx cake clean
