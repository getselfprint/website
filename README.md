# selfprint.org — marketing site

The public, static marketing site for **Selfprint** (landing, privacy, terms).
No build step, no framework — plain HTML/CSS with locally-served fonts, in the
app's design language.

The app itself is a separate repo, [getselfprint/selfprint](https://github.com/getselfprint/selfprint),
and lives at **https://try.selfprint.org**.

## Structure

```
index.html        landing
privacy.html      privacy policy
terms.html        terms
site.css          styles (design tokens inline; no remote CSS)
fonts/            locally-served woff2 (no remote fonts)
robots.txt, sitemap.xml, llms.txt
og.png, favicon.*, apple-touch-icon.png
deploy.sh         static deploy to the droplet (selfprint.org)
indexnow.mjs      IndexNow submission (Bing/Yandex/Seznam/Naver)
```

## Develop

It's static — open `index.html`, or serve the folder with any static server:

```bash
npx serve .        # then visit the printed URL
```

## Deploy

```bash
./deploy.sh        # atomically swaps the files into the droplet, pings IndexNow
```

Serving (nginx on the droplet): `/` is this site; `/privacy` and `/terms` are
clean URLs; legacy `/studio` and `/app` 301-redirect to `https://try.selfprint.org`.
Set the Content-Security-Policy as an HTTP header at the host.
