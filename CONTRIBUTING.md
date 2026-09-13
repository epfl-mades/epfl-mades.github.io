# Editing the MADES website

The site is Jekyll on the [al-folio](https://github.com/alshedivat/al-folio) theme, version 1.2.
Since al-folio v1.0 the theme ships as Ruby **gems**: layouts, includes, styles and runtime
assets live in `al_folio_core` and about eighteen sibling `al_*` gems, and this repository holds
only content, configuration, and two deliberate overrides. Upgrading is `bundle update` plus
`bundle exec al-folio upgrade audit`.

## Running it locally

**Docker is the recommended path** — it is reproducible and closest to what CI does.

```bash
docker compose pull                # the image the compose file names IS the v1.2 image
docker compose up                  # http://localhost:8080, live-reloads as you edit
```

Pull before up: `docker-compose.yml` declares both `image:` and `build: .`, so if the image is
absent Compose builds it from the Dockerfile instead — several minutes of `apt-get` and
`bundle install` for no benefit. The container serves from `/tmp/_site` inside itself, so
`_site/` does not clutter the checkout.

**Native**, via [mise](https://mise.jdx.dev) — needs ImageMagick on the PATH
(`brew install mise imagemagick`):

```bash
mise install                       # Ruby and Node, per .mise.toml
mise run setup                     # the bundler Gemfile.lock pins, then the gems
mise run serve                     # http://localhost:4000
```

Two traps worth naming, because both fail confusingly:

- **`bundle install` on its own will not work.** `Gemfile.lock` pins a `BUNDLED WITH` newer than
  the bundler inside Ruby, and `bundle` refuses to run until that exact version is installed
  (`Could not find 'bundler' (x.y.z) required by your Gemfile.lock`). `mise run setup` reads the
  version out of the lockfile and installs it, so it stays correct after a `bundle update`.
- **`mise install` does not put Ruby on your PATH.** Without shell activation, `bundle` resolves
  to macOS's `/usr/bin/bundle` and its Ruby 2.6 — the traceback names
  `Ruby.framework/Versions/2.6` when this happens. Either activate mise
  (`echo 'eval "$(mise activate zsh)"' >> ~/.zshrc`, then restart the shell) or prefix one-off
  commands with `mise exec --`. Tasks run through `mise run` always get the right Ruby.

Native runs can also hit the usual native-extension pain (`nokogiri`, ImageMagick). Fall back to
Docker when that happens.

## The commands that matter

```bash
docker compose up                                        # local preview
mise run setup                                           # after a clone, or after bundle update
mise run build                                           # production build into _site/
mise run audit                                           # al-folio upgrade contract check
mise run overrides                                       # list local overrides, flag stale ones
mise run fmt                                             # prettier
bundle update && bundle exec al-folio upgrade report     # upgrade, then read the report
```

Under Docker, prefix with `docker compose run --rm jekyll bash -lc "…"`.

## Adding a person

Edit [`_data/people.yml`](_data/people.yml) — one file, one entry per person:

```yaml
- name: Ada Lovelace
  slug: ada-lovelace # the /team/#anchor, and the image filename
  group: students # must match a key under `groups:` at the top of the file
  order: 6 # position within the group
  position: Doctoral Assistant
  image: people/ada-lovelace.jpg
  email: ada.lovelace@epfl.ch # a real address; it is obfuscated at build time
  description: One or two sentences.
  links:
    scholar: XXXXXXXXXXXX # the Google Scholar user id
    orcid: 0000-0000-0000-0000 # the bare id, no orcid.org/ prefix and no scheme
    github: alovelace
    website: https://people.epfl.ch/ada.lovelace
```

Leave out any key that does not apply — the card only renders what is present.

**The photo** goes in `assets/img/people/<slug>.jpg`. Cards render it as a square
(`aspect-ratio: 1 / 1` in `_sass/_mades.scss`), so crop it to a square, face-centered frame
before committing — pick `SIZE` and the `+X+Y` offset so the crop includes the whole face:

```bash
docker compose run --rm jekyll convert INPUT.jpg \
  -auto-orient -crop SIZExSIZE+X+Y +repage \
  -resize 1200x1200 -strip -quality 82 \
  assets/img/people/<slug>.jpg
```

Keep it under 250 KB. Jekyll generates the 480/800/1400 WebP variants at build time; committing
a multi-megabyte original makes every visitor download it. CI rejects anything in `assets/img/`
over 500 KB.

## Adding a publication

Append the BibTeX entry to [`_bibliography/papers.bib`](_bibliography/papers.bib) — Zotero's
Better BibTeX export is what the rest of the file came from. The publications page groups by
year automatically; there is no list of years to maintain.

**Never re-export your whole Zotero library over this file.** A fresh export only carries
standard BibTeX fields — it silently drops `abbr`, `bibtex_show`, `selected`, `award`, and
`preview` from every existing entry, since those are site-specific additions Zotero knows
nothing about. That takes out every venue badge, "Bib" button, and the home page's
selected-papers list in one paste, with no error to notice it by. Instead: in Zotero, select
only the *new* reference(s) → Export Selected Items → Better BibTeX, and append just that to
the file. If you ever do need a full re-export, match old and new entries by `doi` first and
carry the extra fields over by hand before replacing anything.

After adding or changing an entry, always check locally (`docker compose up`, then
`/publications/` and `/`) that its badge, buttons, and (if applicable) the home page listing
look right — a missing `abbr`/`bibtex_show` produces no error, just a paper with no badge or
Bib button.

al-folio reads these extra fields:

| field                                             | effect                                                                                                   |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `abbr`                                            | the venue badge. Add the abbreviation to [`_data/venues.yml`](_data/venues.yml) or it renders uncoloured |
| `selected={true}`                                 | also lists the paper on the home page                                                                    |
| `bibtex_show={true}`                              | adds the "Bib" button                                                                                    |
| `abstract`                                        | adds an expandable abstract                                                                              |
| `html`, `pdf`, `arxiv`, `code`, `supp`, `website` | link buttons                                                                                             |
| `preview`                                         | thumbnail image in `assets/img/publication_preview/`                                                     |
| `award`, `award_name`                             | a highlighted button (e.g. for an "Editor's Suggestion") -- see below                                    |

**Highlighting a paper** (an award, an editor's pick, etc.): add `award` and, optionally,
`award_name`:

```
award = {Selected for its novel approach to defect thermodynamics.},
award_name = {Editor's Suggestion},
```

This adds a button styled in the site's highlight colour, labelled with `award_name` (or
"Awarded" if `award_name` is omitted), that expands on click to show the `award` text --
the same expand/collapse behaviour as the "Abs" button.

**A graphical highlight** (a TOC figure, a schematic, a key result plot): add `preview`. It's
already enabled site-wide (`enable_publication_thumbnails: true` in `_config.yml`), so this is
the only step:

```
preview = {your-slug.jpg},
```

with the image at `assets/img/publication_preview/your-slug.jpg`. It renders as a zoomable
thumbnail beside the venue badge, at the top of the entry's card. A video (`.mp4`, `.webm`,
`.ogg`, `.mov`) works the same way. Keep the same size discipline as team photos -- a
reasonably cropped, compressed image, not a raw multi-megabyte figure export.

Author names are bolded by matching `scholar.last_name` / `first_name` in `_config.yml`. Those
two arrays are paired **positionally** — each row is one spelling of the same person. If a name
renders unbolded, add its spelling to both arrays in the same position.

## Adding a news item

Drop a file in [`_news/`](_news/) named `YYYY-MM-DD-slug.md`. See `_news/README.md` for the
front matter. Items appear on the home page newest first.

## Conventions

- Commit messages carry no AI or assistant attribution.
- Run `mise run fmt` before committing; CI checks formatting.
- `master` is live. Work on a branch.

## Things that fail silently

Worth knowing, because none of them produce an error:

- **A plugin listed in only one of `Gemfile` and `_config.yml`'s `plugins:`** renders nothing at
  all. The two lists must agree. Checking for zero console errors and zero 404s is the only
  reliable way to notice.
- **Tailwind utilities that are not in the prebuilt bundle.** `assets/css/tailwind.css` ships
  pre-purged, with no build step in this repo, so there are no `grid-cols-*`, no `gap-*` and no
  `sm:`/`md:` variants. Using one renders unstyled markup with no warning. Put custom styling in
  [`_sass/_mades.scss`](_sass/_mades.scss) instead.
- **A page whose `permalink` is an absolute URL** gets written out as a real file — `_site/https:/…`
  — and deployed. External navbar links belong in `nav_external:` in `_config.yml`.
