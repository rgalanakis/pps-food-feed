# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.3.4"

# We do not want to install anything in Netlify
group :build do
  gem "appydays"
  gem "base64"
  gem "csv"
  gem "httpx"
  gem "icalendar"
  gem "nokogiri"
end

group :nonproduction do
  gem "pry"
  gem "rubocop"
end
