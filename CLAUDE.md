# GDUXI Studio website: project handoff

GDUXI Studio is a brand and digital design studio run by **Navita Ramanand** (UX/UI design and research) and **Paramdeep Singh** (logo and graphic design). The name stands for **GD** (graphic design) plus **UXI** (UX/UI). The site is a static, single-page portfolio with four hash-routed pages, an editing dashboard at `/admin`, and a contact form that emails the studio. It was designed in Figma first, then built to match that file exactly.

Read this whole file before changing anything. The **Rules** section lists things that are easy to break.

---

## 1. Quick facts

| | |
|---|---|
| Studio email | gduxistudio@gmail.com |
| Navita LinkedIn | https://www.linkedin.com/in/navita-r-122158224/ |
| Paramdeep LinkedIn | https://www.linkedin.com/in/singh1313param/ |
| Location line | Greater Toronto Area · remote worldwide |
| Hosting plan | Netlify (static, no build command), connected to a GitHub repo |
| Dashboard | Decap CMS 3 at `/admin`, GitHub backend with Netlify as the OAuth provider |
| Contact form | FormSubmit AJAX (`https://formsubmit.co/ajax/<email>`), one-time activation needed |
| Design source | Figma file `1ltwd7IDwqNJAJVFJa0eZ7` ("Twofold Studio — Website") |
| Fonts | Julius Sans One (display), Montserrat 400/500/600/700 (body), from Google Fonts |

---

## 2. Folder layout

```
index.html          the whole site: HTML, CSS and JS in one file (about 99 KB)
netlify.toml        publish dir ".", no build; no-cache on content/
favicon.svg         logo mark: gradient rounded square with a white swoosh
content/            ALL editable content as JSON (the dashboard edits these)
  home.json  work.json  studio.json  services.json  contact.json  founders.json  projects.json
assets/             images (jpg/png); dashboard uploads go to assets/uploads/
admin/              Decap CMS: index.html (loads decap-cms@^3 from unpkg) and config.yml
tools/
  sync_content.py   refreshes index.html's built-in backup copy from content/*.json
  check_dashboard.py  checks admin/config.yml fields match content/*.json exactly
tests/
  test_site.py        full Playwright click-through (links, routes, filters, form, overflow, menu)
  test_figma_links.py clicks every case-study card and checks the Figma URL opens in a new tab
README.md           human setup guide (GitHub → Netlify → OAuth → using the dashboard)
```

`index.html` is the source file: edit it directly. Nothing compiles it.

---

## 3. How the page works

### Routing
- Four "pages" are `<div class="page" data-page="home|work|studio|services">` blocks. Only one is visible at a time; the others carry `hidden`.
- Routes come from `location.hash`: `#home`, `#work`, `#studio`, `#services`, and `#contact`. `#contact` shows the services page and scrolls to `<section id="contact">`.
- Any element with `data-route="x"` navigates to that route. If it also has `data-need="n1|n2|n3"`, it pre-ticks that service radio on the contact form.
  - `n1` = Brand identity
  - `n2` = UX/UI & digital
  - `n3` = Brand + digital (the default)
- Unknown hashes are ignored, so the skip link (`#main`) works.
- `document.title` updates per page.
- Sticky nav offset: `#contact, #built-together, #more-work, #main { scroll-margin-top: 84px }`.

### Content loading
1. On load, `<html>` gets the class `cms-loading`, which hides `main` and `footer` with `visibility:hidden`. A 3.5 s failsafe removes it.
2. The script fetches all seven `content/*.json` files in parallel, with a 4 s timeout each. Any file that fails falls back to the inline `<script type="application/json" id="content-fallback">`.
3. `[data-c="file.field"]` elements get their text from content. Newlines become `<br>`. Text is HTML-escaped.
4. `[data-ci="file.field"]` images get their `src` from content; `data-alt` becomes the `alt` text, with `{name}` replaced by `home.hero_project_name`.
5. Lists are rendered from data: marquee, stats, why-points, steps, values, included, FAQ, founders, services, projects, contact rows, footer founders.
6. The script then removes `cms-loading` and shows the current route.

### Helpers in the script
- `esc()` HTML-escapes all inserted text.
- `nl()` escapes text and turns newlines into `<br>`.
- `safeUrl()`:
  - converts `/assets/...` to `assets/...` (the dashboard stores site-absolute paths)
  - allows `http(s):`, `mailto:`, `#` and `assets/` as they are
  - adds `https://` to bare domains.

### Category tags
Projects, services and steps use a category: `bd` (Brand + Digital), `dg` (Digital) or `id` (Identity).
- Labels come from `TAGS = {bd:"Brand + Digital", dg:"Digital", id:"Identity"}`. **No founder names on tags** (owner request).
- Tag styles: `.tag.bd` is a gradient pill, `.tag.dg` a lilac pill, `.tag.id` a sky-blue pill.

### Projects (`content/projects.json`)
Fields: `title`, `figma`, `group` (bd/dg/id), `label` (year or type), `cover`, `logo`, `screen`, `pages` (list of case-study image paths), `pieces[{kind,label,image}]` (labelled campaign pieces shown as a grid in the case pop-up: landscape images span half the width, portrait ones a third; 2 columns on phones, 1 below 520px), `screens[{label,stage,device,image}]` (screenshots; `stage` is `hifi` (default) or `lofi`, `device` is `desktop` or `mobile`), `short`, `who` (credit line), `description`, `facts[{label,value}]`.

`screen` is the right-hand image on a Built together card (logo ⟶ screen). It falls back to `cover` when empty.

- **If `figma` is set**, the card is an `<a class="proj">` (or `<a class="joint">`) with `target="_blank" rel="noopener noreferrer"`. It opens that project's Figma file. Link text ends in ↗.
- **If `figma` is empty**, the card is a `<button>`, and the joint card an `<article role=button>`. It opens the case-study `<dialog id="caseDlg">`. If `pages` has images, the dialog widens to 1100px and shows them stacked under the title (in `#casePages`) instead of the cover.
- **If `screens` has images**, the card (and joint card) is an `<article>` with two buttons: "View screens →" opens `<dialog id="shotsDlg">`, and "Open in Figma ↗" opens the Figma file in a new tab. The gallery has a Hi-fi designs / Lo-fi wireframes switch (shown when a project has both), Desktop / Mobile tabs, numbered labels, and shareable links `#screens/<title-slug>` and `#screens/<title-slug>/lofi` (e.g. `#screens/canada-bank/lofi`); closing it restores the previous hash.
  - Screens live in `assets/img/screens/<project>/NN-<device>-<label>.jpg`, exported at 1x from each project's hi-fi Figma page (2026-10-30). N'Cafe has no mobile hi-fi frames, so it shows desktop only.
  - Lo-fi wireframes live in `assets/img/lofi/<project>/NN-<device>-<label>.jpg`, exported at 1x from each file's lo-fi page (2026-10-30): N'Cafe 4 desktop, Artisan 4 + 4, Canada Bank 5 + 5, RS Tour 1 + 1.
- Where projects appear:
  - **Home "Selected work"** grid (`[data-projects="all"]`) shows all projects in a 3-column grid.
  - **Work "Built together"** (`#joints`) shows `bd` projects as large joint cards: logo + arrow + cover, then facts. The first joint card has a decorative "Layers" pop. With no logo, the cover spans the full width at 16:10.
  - **Work "More projects"** (`#more-grid`, `data-projects="dg,id"`) shows `dg` and `id` projects in a 2-column grid.
- Work filters show counts: "All work · N", "Brand + Digital · N", "Digital · N", "Identity · N".
  - `bd` shows only Built together.
  - `dg` / `id` show only More projects, filtered to that category.
  - Any filter other than "All" scrolls to its section. Filter buttons use `aria-pressed`.

### Contact form (`#cform`)
- Fields: name, email, need (3 radios), budget (select), timeline (select), message.
- Validation messages appear in `aria-live` spans:
  - name is required
  - email must match an email pattern
  - message must be at least 10 characters
- On submit, the script sends a POST with a JSON body to `https://formsubmit.co/ajax/` + `contact.email`. It sends `_subject` "New project enquiry from the GDUXI website" and `_template` "table", with a 12 s timeout.
- Success means `r.ok` **and** `json.success !== "false"`. Before activation, FormSubmit returns `success:"false"`, which counts as a failure.
- **On success**, `<dialog id="sentDlg">` shows `#sentOk`: "Thanks, {first name}", with "Back to home" and "See our work" buttons.
- **On failure**, it shows `#sentFail`:
  - "Open my email app": a pre-filled `mailto:`
  - "Send with Gmail": a pre-filled Gmail compose link, opened in a new tab
  - the plain email address
- `fixMailTargets()`: when the page is framed (a preview iframe), every `mailto:` link gets `target=_blank`; otherwise sandboxes swallow it.
- Every `mailto:` link and email text on the page is rewritten from `contact.email`.

### Other behaviour
- **Mobile menu** (`#mmenu`, below 900px): a full-screen `role=dialog`. It has a focus trap and closes on Escape, the ✕ button, or any route click.
- **Back to top** button in the footer.
- **Reveal:** cards below the fold slide up 18px on scroll via IntersectionObserver. Content stays visible at rest. This is skipped with reduced motion.
- **Waves:** decorative SVG wave-line bundles generated by `waveSVG(kind,n)` into `[data-wave]` elements. The shape comes from Paramdeep's banner artwork.
- **Accessibility:**
  - "Skip to content" link
  - visible focus rings
  - all icons `aria-hidden`
  - new-tab links carry sr-only "(opens in a new tab)"
  - every interactive element has an accessible name (verified by the tests)

---

## 4. Page structure (current, in order)

**Nav (all pages):** logo (links home) · Work · Studio · Services · Contact · "Start a project →" button. Below 900px it becomes a burger menu.

**Home**
1. **Hero**
   - Eyebrow "Brand + digital design studio"
   - Headline "Brand to screen." with a gradient line "In one flow." and a swoosh underline
   - Intro paragraph
   - Buttons: "Start a project" (→ contact) and "See our work" (→ work)
   - Right side, a composition:
     - RS logo card: "01 · The mark", Identity tag
     - joiner text "one brand, flowing from mark to screen"
     - RS website card: "02 · The experience", Digital tag
     - a floating wireframe pop, sparkles, crop marks and a scroll cue
2. Marquee of service words.
3. **The founders** (introductions):
   - Heading "Two crafts. One studio." and an intro paragraph
   - "Meet the studio" button (→ studio)
   - Two founder cards (photo, signature logo, name, role, bio, "Leads" tag, skills, LinkedIn ↗)
   - Spinning "GD × UX/uI · ONE STUDIO" badge between the cards
   - Outline word "GD UXI" behind the section
4. Stats strip: 28+ / 10+ / 5+ / 1.
5. **What we do:** 3 service cards; the 3rd is featured (band gradient). The whole card links to contact with that service pre-selected. "All services" button.
6. **Selected work:** 6 project cards. "View all work" button.
7. **Why one studio:** blue band with 3 numbered points.
8. **How we work:** 4 steps, each with a category tag.
9. CTA band (shared by all pages):
   - "Have a brand that needs a mark, / and a site that needs to work?"
   - "Start a project" button
   - spinning badge

**Work**
- Header: "Work that holds together", intro, filter pills.
- **Built together · mark to screen:** "Where Graphic Design meets UX/uI" (casing as the owners wrote it), with 2 joint cards.
- **More projects:** "Identity and digital work", 4 cards in 2 columns.
- CTA band.

**Studio**
- Header: "Two crafts. One studio." and intro, spinning badge.
- **Why GDUXI** story card: app-icon mark, statement, paragraph.
- **The founders:** "Equal partners, side by side". Detailed founder cards, each with a "Background" list.
- **What we believe:** "Three promises to every client".
- CTA band.

**Services & contact**
- Header: "Pick a speciality, or get both".
- 3 service cards.
- **Included in every project:** 4 check cards.
- **Questions:** FAQ as `<details>`, first one open.
- **Contact** (`#contact`):
  - Band-gradient contact card: logo, heading, intro, then rows for Email, Navita on LinkedIn, Paramdeep on LinkedIn and Where
  - The form card.

**Footer (all pages):**
- Logo, tagline "Brand to screen. In one flow." and a description
- Studio links
- Founders LinkedIn links
- Say hello: email and reply note
- "© 2026 GDUXI Studio" and Back to top

---

## 5. Design tokens (`:root` in index.html)

```
Brand:   --blue #045FEA  --blue-2 #3F7EFC  --violet #8549FF  --lilac #A76EFF  --orchid #D75FFF
         --sky #8AD2FD  --sky-100 #E0EDFF  --lavender #F2DDFF  --pink-deep #B33DDB (section eyebrows)
Neutral: --ink #1F2A44  --ink-soft #2A3555  --muted #5D6680  --line #E3E7EF  --paper #FFF  --cream #FCF7EE  --mist #E7EEF8
Bands:   --band-1 #7C95D2  --band-2 #9A97E2  --band-3 #B38ADE  (white text on bands; eyebrows on bands use pale pink #FFE1FF)
Gradients:
  --grad   90deg  #045FEA → #8549FF → #D75FFF   (signature: buttons, gradient text, badges)
  --dawn  135deg  #E0EDFF → #F0EDFD → #F8E2FB   (page headers, hero, contact)
  --band  135deg  band-1 → band-2 (60%) → band-3  (footer, why band, CTA, featured card, story, contact card)
  --soft  135deg  #EDF3FD → #FFF → #E6F0FF
Shadows: --shadow-soft 0 12px 32px rgba(4,95,234,.12) · --shadow-lift (hover)
Type:    --f-display Julius Sans One (headings, big numbers) · --f-body Montserrat
Radius:  --r-card 24px (joint cards 28px)   Max width: --max 1200px
Breakpoints used: 1100, 1020, 980, 900 (nav→burger), 860, 760 (phone tweaks), 640, 520
```

On phones (760px and below), the hero name tags sit on the images, crop marks are pulled in, and the joint cards show only the cover image. Page-header waves are lighter, the Studio badge moves to the top-right corner, and footer links don't wrap.

The logo:
- Mark: gradient rounded square (`--grad`, radius 12 on 40px) with the white swoosh path `M9 25.5C12.5 13 17 11.5 19.5 18.5C21.5 24.5 25 27.5 31.5 14` and a white dot at (31.5, 14).
- Wordmark: "GD" in blue plus "UXI" in gradient, Julius Sans One, 14% letter-spacing. "STUDIO" below in small caps with wide spacing.
- **Keep this original logo.** The owners rejected a redesign.

---

## 6. Projects and their Figma links

| Project | Category | Opens |
|---|---|---|
| RS Tour & Traveler | Brand + Digital | `figma.com/design/oWHsEHVMx038r51olfe0uv/...?node-id=34-1449` (website file, cover page) |
| The N'Cafe | Digital | `figma.com/design/xtYAcKAoR4VHk0wFkWY93H/...?node-id=0-1` |
| Ek Oankar | Identity | No Figma link: opens the on-site pop-up with `assets/img/case-ek-oankar-1/2.jpg` (exported from Paramdeep's portfolio, case study 02, node `25:1051`) |
| Artisan Crafts | Brand + Digital | `figma.com/design/17WEqDMeY9NPCAWhZvrvS1/...?node-id=0-1` (brand guide + lo/hi-fi file) |
| Canada Bank | Digital | `figma.com/design/uO4KBkt4W3AKwAXOf16xPE/...?node-id=0-1` (fictional bank concept) |
| RS Tour campaigns | Identity | No Figma link: opens the on-site pop-up with five labelled pieces in `assets/img/rs-campaigns/` (2 banners, 2 stories, 1 flyer, laid out as a grid) and `assets/img/case-rs-campaigns-2.jpg` (portfolio nodes `25:972` "Campaigns & print" and `25:1048` "Result") |

The owner asked (2026-10-29) that these two cards show only their own project, not the rest of Paramdeep's portfolio file, so they no longer link to Figma. The full URLs for the other four are in `content/projects.json`. Each file must be shared as **"Anyone with the link · can view"**, or visitors see a request-access screen. The owners have to do this in Figma.

---

## 7. The Figma design file (`1ltwd7IDwqNJAJVFJa0eZ7`)

Pages:
- **Foundations** `0:1`: tokens and components:
  - Tag/Identity · Tag/Digital · Tag/Brand + Digital
  - Logo variants, Buttons
  - Project Card · Founder Card · Service Card (+ Featured)
  - Nav/Footer (Desktop and Mobile)
  - Pop/* decorations and Pattern/* waves
  - variables including `pink-deep`
- **Desktop** `3:2`:
  - Home `6:48` · Work `10:352` · Studio `11:492` · Services & Contact `12:611` (contact section `12:689`)
  - Message-sent overlay `82:2323`
  - Old case-study overlays `82:1985`–`82:2267` are no longer linked and can be deleted.
- **Mobile** `3:3`:
  - Home `21:48` · Work `22:280` · Studio `22:456` · Services `22:618` (contact `22:733`)
  - Menu overlay `84:1528` · sent `84:1515`
  - Old case overlays `84:1375`–`84:1493` are unlinked.

The prototype is fully wired:
- nav and routes
- case-study cards open the Figma URLs above in a new tab
- LinkedIn and email links

The mobile Figma frames are an older content version, without the FAQ or the "Three promises" section. The site follows **desktop** Figma for content and mobile Figma only for layout.

---

## 8. Owner decisions to respect

- **No founder names** outside the founder introductions. Names stay in:
  - founder cards
  - the Home founders intro paragraph
  - the "Background · Name" headings
  - footer LinkedIn links
  - contact LinkedIn rows
  - the meta description

  Tags are categories only. "Led by one founder" and "How we share the work" were removed on purpose.
- **No "two founders" or "two-founder" wording.** Headings read "Two crafts. One studio."
- **Removed decorations:**
  - Don't re-add the hero Pen-tool and Palette cards, the "Logo approved" and "Brief received" toasts, the "282 px" spec line, the visible service-card "Start with this →" links, or the Copy-email button.
  - Floating founder name tags (cursors) were removed everywhere.
- **"UX/uI" casing:** kept exactly as the owners wrote it in Figma. Ask before "fixing" it.
- **Colours:**
  - Blue and pink stay in equal balance.
  - The navy bands were deliberately lightened to the band-1/2/3 values above, with white text.
- **Section order:** founders section directly after the hero on Home.

---

## 9. Dashboard (Decap CMS)

`admin/config.yml` has one collection, "Website", with 7 file entries:
- Projects
- Founders
- Home
- Work
- Studio
- Services & FAQ
- Contact & footer

Settings:
- Images upload to `assets/uploads` and are stored as `/assets/uploads/...`.
- `publish_mode: simple`, so saving publishes straight away.
- `local_backend: true`, so `npx decap-server` lets you test locally.
- `backend.repo` is `paramzgraphic-arch/gduxi-website`, branch `main`.

Netlify OAuth setup:
1. Create a GitHub OAuth App with callback `https://api.netlify.com/auth/done`.
2. In Netlify, go to Project configuration → Security → OAuth → Install provider → GitHub.

This was never tested live (no network when it was built). The config was checked against Decap's schema, and the site side was tested with simulated edits.

---

## 10. Rules (easy to break)

1. **Add new content fields in three places:**
   - the JSON file
   - `admin/config.yml`, or the dashboard silently drops the field on the next save
   - the render code in `index.html`

   Then run `python3 tools/check_dashboard.py`.
2. **After hand-editing `content/*.json`,** run `python3 tools/sync_content.py` so the inline backup and the static text match.
3. **Escape** all content through `esc()`, `nl()` and `safeUrl()`. Never insert raw content HTML.
4. **Keep `target="_blank" rel="noopener noreferrer"`** and the sr-only new-tab note on external links.
5. **Don't change the form success check.** FormSubmit returns HTTP 200 with `success:"false"` before activation.
6. **Keep `fixMailTargets()`.** Without it, email links do nothing inside preview iframes.
7. **Check against the owners' Figma** before adding visual elements. They removed several extras and noticed.
8. **Test at 1440px and 390px:** no horizontal overflow, and no JS errors.

## 11. Testing

```bash
python3 -m http.server 8000                       # in this folder
pip install playwright pyyaml && playwright install chromium
python3 tests/test_site.py http://localhost:8000/index.html
python3 tests/test_figma_links.py http://localhost:8000/index.html
python3 tools/check_dashboard.py
```

Last run, all passed:
- 84 interactive elements with 0 accessibility issues
- all route links work
- filters work
- form success and failure paths both work
- 0 overflow
- 0 JS errors
- 12 of 12 Figma links open correctly on desktop and phone

## 12. Open items

- [ ] Do the GitHub/Netlify/OAuth setup in README.md, then test a real dashboard login and save.
- [ ] Activate FormSubmit: send one message from the live site, then click "Activate form" in the email that arrives at gduxistudio@gmail.com. Alternative: switch to Netlify Forms.
- [ ] Set the four linked project Figma files to "Anyone with the link · can view".
- [ ] Optional: reword the remaining "founder" phrases if the owners want: "Both founders read every message", "with both founders", "Hire either founder", "the other founder still reviews".
- [ ] Optional: delete the unlinked case-study overlay frames in Figma, and bring the mobile Figma frames up to date with desktop content.
- [ ] The meta description still names both founders. Ask the owners whether to keep it (it helps search).

## 13. Rebuild history

- **2026-10-29:** the original files were lost (the GitHub repo was empty), so the site was rebuilt from this document plus the desktop Figma frames. Images in `assets/img/` were exported from Figma at 1x (the Figma connector cannot reach figma.com asset URLs from the cloud sandbox), so photos and covers are 1x. Re-export at 2x from Figma when convenient and drop them in with the same file names.
- Decorations that are in Figma but were left out on purpose, per section 8: the Pen tool (Pop/Bezier) and Palette (Pop/Swatch) cards, and both Pop/Toast pills ("Case study live", "We reply in 2 days").
- Tests on that date: `test_site.py` all passed at 1440px and 390px (114 and 98 interactive elements, 0 overflow, 0 JS errors); `test_figma_links.py` 12 of 12 on desktop and phone (the Built together cards count separately from the grid cards). Run with `PW_CHROMIUM=/path/to/chrome` if Playwright's own browser is not installed.
