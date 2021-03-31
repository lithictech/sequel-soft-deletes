staging_app:=webhookdb-api-staging
production_app:=webhookdb-api-production

install:
	bundle install
cop:
	bundle exec rubocop
fix:
	bundle exec rubocop --auto-correct-all
fmt: fix

test:
	RACK_ENV=test bundle exec rspec spec/
	@./bin/notify "Tests finished"
testf:
	RACK_ENV=test bundle exec rspec spec/ --fail-fast --seed=1
	@./bin/notify "Tests finished"