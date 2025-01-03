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

serve:
	@bundle exec ruby bin/serve.rb
