pps-food-feed
==

Generates iCalendar feeds for Portland Public Schools nutritional services menus.

PPS Nutritional Services manually creates the menu PDF each month,
so there is no automated system available for menus.

The .ics generation process:

- Parses https://www.pps.net/Page/214 to find menu PDFs
- Saves them to the repo
- Parses the PDF using Anthropic LLM into a CSV.
- Converts the CSV into iCalendar feeds, one for each menu found on the site.
- Each stage (pdf download, LLM parsing) is cached in the repo.

The feed generation is run:

- In a GitHub action that runs nightly.
- It generates a PR if there is a diff.
- Review and merge the PR, which will cause a rebuild/deploy.

The site:

- Generates a link to a feed if the feed has any fetches in the last 3 months 
  (some menus may be for previous school years).
- Is built and served by Netlify, since we need Content-Disposition headers.

### Configuration

Check out `pps_food_feed.rb` for current configuration options.

- `LOG_LEVEL=debug`: Default app log level. Defaults to print all output.
- `LOG_FORMAT=json_trunc`: Log format. Defaults to JSON.
- `ANTHROPIC_API_KEY`: API key for Anthropic.
- `PPSFOODFEED_SKIP_FETCH=false`: Onlu useful during local development. Skip this part of the build process.
- `PPSFOODFEED_SKIP_CSV=false`: Onlu useful during local development. Skip this part of the build process.
- `PPSFOODFEED_SKIP_ICS=false`: Onlu useful during local development. Skip this part of the build process.
- `PPSFOODFEED_SKIP_INDEX=false`: Onlu useful during local development. Skip this part of the build process.
- `SITE_HOST=https://ppsmenus.net`: Only modify if self-hosting.

### Development

Set environment variables for add a `.env.development.local` file to locally override configuration options.

Check out the `Makefile`, it is the entrypoint for everything. You may need to add support for your OS.

```sh
$ make dev-install
$ make dev
```

# Contact

For help, post an issue or contact Rob Galanakis, rob.galanakis@gmail.com
