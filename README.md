pps-food-feed
==

Generates iCalendar feeds for Portland Public Schools nutritional services menus.

PPS Nutritional Services manually creates the menu PDF each month,
so there is no automated system available for menus.

The .ics generation process:

- Parses https://www.pps.net/Page/214 to find menu PDFs
- Saves them to the repo, along with a PNG to help change tracking
- Parses the PDF using Anthropic LLM into a CSV.
- Converts the CSV into iCalendar feeds, one for each menu found on the site.
- Each stage (pdf download, LLM parsing) is cached in the repo.

The menu generation is run:

- In a GitHub action that runs nightly.
- It generates a PR if there is a diff.

The site:

- Is served using GitHub pages.
- Generates a link to a feed if the feed has any fetches in the last 3 months
  (some menus may be for previous school years).

For help, post an issue or contact Rob Galanakis, rob.galanakis@gmail.com
