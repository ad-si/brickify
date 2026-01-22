.PHONY: help
help: makefile
	@tail -n +4 makefile | grep ".PHONY"


.PHONY: typecheck
typecheck:
	npx tsc --noEmit


.PHONY: build-workers
build-workers:
	npx vite build --config vite.config.workers.ts


.PHONY: build
build: typecheck build-workers
	npx vite build


# The main server part which is responsible for delivering the
# website and for server-side plugin integration and model processing
.PHONY: start
start:
	npx ts-node --esm bin/cli.ts start


# .PHONY: link-hooks  # Links git hooks into .git/hooks
# link-hooks:
# 	cakeUtilities.linkHooks()


.PHONY: lint
lint:
	npx eslint --ignore-pattern=.gitignore .


.PHONY: test
test:
	npx tsx node_modules/mocha/bin/mocha --recursive --extensions ts 'test/**/*.ts'


.PHONY: test-client
test-client:
	npx vitest run


.PHONY: prepublish
prepublish:
	npm test && npm run check-style


.PHONY: clean
clean:
	rm -rf node_modules
	rm -rf public


.PHONY: build-static
build-static:
	npx vite build --config vite.config.static.ts
	npx ts-node --esm scripts/build-static-html.ts
	@echo "Static build complete in dist-static/"
	@echo "Open dist-static/index.html in your browser to run without a server"
