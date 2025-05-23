.PHONY: help
help: makefile
	@tail -n +4 makefile | grep ".PHONY"


.PHONY: build
build:
	npx cake build
	cakeUtilities.buildServer()


# The main server part which is responsible for delivering the
# website and for server-side plugin integration and model processing
.PHONY: start
start:
	require './src/server/main'
		.setupRouting()
		.startServer()


# .PHONY: link-hooks  # Links git hooks into .git/hooks
# link-hooks:
# 	cakeUtilities.linkHooks()


.PHONY: lint
lint:
	npx eslint --max-warnings=0 --ignore-pattern=.gitignore .


.PHONY: test
test: # check-style
	npx mocha --recursive


.PHONY: test-client
test-client:
	npx karma start


.PHONY: prepublish
prepublish:
	npm test && npm run check-style


.PHONY: clean
clean:
	npx cake clean
