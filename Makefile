install:
	bundle install
cop:
	bundle exec rubocop
fix:
	bundle exec rubocop --autocorrect-all
fmt: fix

pry:
	@bundle exec pry

