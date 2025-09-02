install:
	bundle install
cop:
	bundle exec rubocop
fix:
	bundle exec rubocop --autocorrect-all
fmt: fix

pry:
	@bundle exec pry

build:
	@bundle exec ruby bin/build.rb

## Install MacOS prerequisites for running the dev server.
dev-install:
	brew install fswatch coreutils

## Run the development server (rebuild the site when certain files change).
dev:
	@echo "Watching for changes to /site"
	@fswatch -o site | xargs -n1 -I{} make _dev-build

_dev-build:
	@start=$$(gdate +%s%3N); \
		echo "Building..."; \
		make build; \
		tput cuu1; \
		tput el; \
		end=$$(gdate +%s%3N); \
		echo "Build completed in $$((end - start))ms"; \
		osascript -e "display notification \"Build completed in $$((end - start))ms\" with title \"PPS Food Feed\"";

serve:
	@bundle exec ruby bin/serve.rb
