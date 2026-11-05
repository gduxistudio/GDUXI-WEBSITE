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
| RS Tour & Traveler campaigns | Identity | No Figma link: opens the on-site pop-up with five labelled pieces in `assets/img/rs-campaigns/` (2 banners, 2 stories, 1 flyer, laid out as a grid) and `assets/img/case-rs-campaigns-2.jpg` (portfolio nodes `25:972` "Campaigns & print" and `25:1048` "Result") |

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

---

## 14. Experiments branch redesign (2026-11-05, not on main)

Prm asked for these on `experiments` only. They override sections 1, 4, 5 and 6 on this branch.

- **Home order:** Hero → marquee → Selected work (`.work-first`, more padding) → Founders → stats → services → why → process → CTA.
- **Hero:** the text headline is now a screen-reader-only `h1`; on screen it is replaced by `assets/img/hero-studio.svg` (logo mark with bezier anchors overlapping a website window and phone, joined by one line). Dashboard fields `home.hero_graphic` and `home.hero_graphic_alt`. Only the "See our work" button remains (gold primary); the hero "Start a project" button was removed at Prm's request.
- **Fonts:** Bricolage Grotesque (display, 500–800) + Inter (body 400–700). Julius Sans One is loaded only as a `text=GDUXI` subset for the logo wordmark (`--f-logo`).
- **Type scale** (desktop / ≤760px): H1 `.d-xl` 68/42 700 · H2 `.d-l` 48/34 700 · H3 `.h2` 34/27 650 · H4 `.h3` 22/20 600 display · H5 `.h4` 18 Inter 600 · lead 18/17 · body 16/1.65 · small 14 · caption `.eyebrow` 12 uppercase .16em · button 15 600. Sizes live in `--fs-*`.
- **Palette (accented analogous):** blue → violet → orchid analogous base, gold accent (violet's complement). 60% neutrals, 30% purple (blue supports), 10% gold.
  - Purple `--p-50…900` (softer violet, Prm's pick 2026-11-05 over the original vivid #8549FF): F5F2FD EBE5FB D8CEF5 BEAEEF A893EA **8A6FE0** 6F55C9 5B45AE 47378A 2F2560. The logo keeps its original gradient.
  - Blue `--b-50…900`: EEF4FF DCE9FF B5D0FF 7FAEFF 3F7EFC **045FEA** 034FC4 033F9C 022F74 01204F
  - Gold `--g-50…900`: FFF9EB FFF0C7 FFE08F FFCF57 **FFBE2E** F5A70A D18A00 A36A00 6E4700 3D2700
  - Orchid (gradient end + Identity tag): FBEAFF D75FFF 8A1FAF
  - Neutrals: FFFFFF, mist F4F1FA, ECE8F5, line E2DEEC, 9C97B0, muted 5E5874, 2E2948, ink 1D1933
  - Bands 3F3D9E → 5A48B8 → 7158C6 (white text ≥ 5.3:1, gold-100 eyebrows 4.7:1; the old light bands were 2.7:1 and failed AA). Footer 2F2560 → 47378A → 3F3D9E.
  - Roles: gold = primary CTA buttons, eyebrow rules, nav underline, highlights; purple 600/700 = links, secondary buttons, card buttons, active filters, Brand + Digital tag; blue 50/700 = Digital tag; orchid 100/700 = Identity tag.
  - All text/background pairs checked to WCAG AA (script check, 0 failures on the four pages).
- **Project cards:** "Open in Figma" and "Open the full Figma file" now read "View Prototype ↗". The Canada Bank "Concept" label and "concept" wording were removed (empty `label` is not rendered).
- **Preview:** Netlify branch deploys are on (2026-11-05), so this branch builds at https://experiments--gduxistudio.netlify.app. Non-production deploys need a Netlify team login.
- **Prototype links:** `figma` URLs now use `/proto/` with each file's desktop flow starting point (RS Tour 7:85, N'Cafe 2:319, Artisan 12:5, Canada Bank 30:2129), so visitors land in prototype view.

## 15. Copy rewrite (2026-11-05, experiments only)

Prm asked for all site copy to be rewritten by a UX writer: warm and human, still professional. Changed: hero intro, section intros, stats labels, why points, steps, values, service summaries, included items, FAQ answers, contact and footer lines, both founder bios (same length and structure, no pronouns), project summaries and descriptions, form labels, validation and sent/failed messages, page titles, meta and og descriptions, cover alt text and the lo-fi gallery note.

Kept on purpose: "Two crafts. One studio.", "Brand to screen. In one flow.", "Where Graphic Design meets UX/uI", "Your brand shouldn't change at the browser.", all facts, numbers, credentials, project names, links and the form email subject. No "founder" wording was added; "Both founders read every message" now reads "We both read every message".

- 2026-11-05: Prm asked for the spinning circle badge to read all capitals, so it is now "GD × UX/UI" (experiments only). The "Where Graphic Design meets UX/uI" heading keeps its casing.
- 2026-11-05: on phones (760px and below) project thumbnails show the whole image at its own shape instead of a fixed 250px crop (experiments only).
- 2026-11-05: proj-rs-tour.jpg and proj-artisan.jpg were cropped 358x250 exports; replaced with full 16:9 covers (1124x633) from each project file's cover frame (RS Tour 34:1449, Artisan 18:2241). On wider cards they anchor left so the title side shows.
- **Casing (2026-11-05):** Prm asked for every "UX/UI" in capitals. This overrides the old "UX/uI" rule in section 8. Headings use Title Case through CSS `text-transform:capitalize`.
- **Decorations stay inside the guidelines:** badges and pops sit inside `.wrap` (class `badge in-wrap`) or use `right:max(var(--gut),calc(50% - 600px))`, so none of them gets cut off at the screen edge. There is no badge on the purple CTA banner.
- **Thumbnails (2026-11-05):** every `assets/img/proj-*.jpg` is now a full 16:9 cover at 1124x633 (Canada Bank from Figma node 21:3356, N'Cafe from 1:7 trimmed to 16:9, Ek Oankar cropped from case-ek-oankar-1.jpg, RS campaigns a collage of the five pieces on cream). `.proj .cover` is `aspect-ratio:16/9`, so the whole image shows at every width. Replacement covers must be 16:9.
- On phones the "GDUXI" outline word sits at `right:var(--gut)` so the I stays on screen.
- Later on 2026-11-05: Prm asked for single-image covers on two cards. Ek Oankar is back to its navy logo cover, now padded to 16:9. "RS Tour & Traveler campaigns" (renamed from "RS Tour campaigns") uses only the Visit the Taj Mahal banner, at full width over a blurred fill to 16:9.

## 16. Version 2.0 (2026-11-05, experiments only)

Prm named this state of `experiments` **2.0** and asked for an accessibility test. Snapshot branch: `release/2.0` (git tags can't be pushed from the sandbox).
- Phones: the "GDUXI" outline word lines up with the text column above the eyebrow (Home founders and Studio founders), with less padding, so there's no empty gap.
- Accessibility fixes: footer column titles are `h2` (were `h4`, which skipped levels); a screen-reader-only "Our services" `h2` on the Services page; marquee has `role="group"`; eyebrows use purple 700 (#5B45AE) so 12px text stays above 4.5:1 over the light gradients; on phones the top-right hero/page-header blob is at 45% opacity for the same reason; the "Layers" pop uses blue 700.
- WCAG 2.2.2: a round pause button on the marquee (`.motion-btn`, `aria-pressed`) pauses every looping animation via `html.no-motion` and is remembered in localStorage. The marquee also pauses on hover or focus. Reduced-motion users get no animation and no button.
- WCAG 2.5.8: footer "Back to top" and founder-card LinkedIn links are at least 24px tall; footer links use line-height 1.75.
- Results: axe-core 4.10 (WCAG 2.0/2.1/2.2 A+AA + best practice) 0 violations in 19 views; pixel-measured contrast 0 of 805 text items below AA; keyboard focus ring on every stop; skip link works; no sideways scroll at 320px, 200% text or text-spacing overrides.

## 17. Home hero, layout A (2026-11-05, experiments only)

- Nav and footer have a "Home" link before Work (the phone menu already had one).
- The hero's "01 · The mark" / "02 · The experience" pictures, crop marks, wireframe pop, scroll cue, glow, second blob and sparkles were removed to make the page less crowded. The CMS fields `home.hero_mark_*`, `hero_site_*`, `hero_joiner`, `hero_project_name` are now unused.
- Prm compared four layouts (previews in /mnt/project-files/previews/hero-options-2026-11-05/) and chose **A**: eyebrow, the visible headline "Brand to screen." / "In one flow." (gradient second line, `.hero-h`), intro and "See our work" on the left; `hero-studio.svg` on the right (`.hero-visual`). Stacks to one column at 1020px and below.

## 18. Header button in logo colours (2026-11-05, experiments only)

Prm asked for the logo gradient on the header "Start a project" button only (`.nav-links+.btn-primary`): `90deg #045FEA → #8549FF 50% → #A22BD1` with white text (the logo's own #D75FFF end is 3.0:1 with white, so the last stop is the darker orchid, 5.5:1). Every other primary button stays gold. A first try that recoloured all buttons was rejected.

## 19. Hero, pop-ups, parallax and skeletons (2026-11-05, experiments only)

- Hero background ends in a softer cream (`#FFF9EE` instead of the dawn gradient's `#FFF5DE`), so the yellow corner is fainter. Page headers keep `--dawn`.
- Every dialog (sent, case, screens) has one close button `.dx` as its first child: sticky in the top-right corner, so it stays put while the pop-up scrolls. The old `.x` buttons are gone (tests updated).
- While any dialog is open the page behind can't scroll: `html:has(dialog[open]){overflow:hidden}` plus `overscroll-behavior:contain` on dialogs.
- Parallax: blobs, waves, glows, dots, outline words and the hero art drift at their own speed on scroll (CSS `translate`, capped at ±60px, 60% on phones). Off with reduced motion and with the marquee pause button.
- Skeletons: any image still loading gets class `ld` (shimmer placeholder, with a sensible aspect ratio in the screens and case pop-ups), added by a MutationObserver, removed on load or error.
- Card buttons read "Screens →" (accessible name "View screens of <project>") and "Prototype ↗" (plus the sr-only new-tab note). A round arrow-only version was tried first and replaced at Prm's request.

## 20. Dark mode (2026-11-05, experiments only)

The site follows the device's light/dark setting (`prefers-color-scheme`); there is no toggle. Prm asked for it after a black bar showed in the screens pop-up (dialogs had no background of their own, so a dark device painted them black).
- Surface tokens in `:root`: `--surface` (cards, dialogs, pills, was `#fff`), `--well`/`--well-2` (pop-up galleries), `--sk1`/`--sk2` (skeleton), `--hero-bg`, `--nav-bg`, plus `color-scheme`. Purple 700 as text or border now goes through `--link`. Use these tokens for new light surfaces, not `#fff`.
- Dark values: page `#100E1E`, cards `#1B1832`, mist `#15122A`, line `#2F2A4C`, ink `#F2EFFA`, muted `#B2ABCA`, link `#C3B5F2`, lighter text gradient `#7FAEFF → #B4A2F0 → #E39BFA`. Bands, footer, gold buttons and the header gradient button stay as they are.
- Component tweaks sit in a `@media (prefers-color-scheme:dark)` block at the end of the stylesheet: header logo uses its on-dark colours, Digital/Identity tags, dimmed blobs and glow, outline word, select arrow, form errors, signatures (inverted with `screen` blend), focus ring.
- Checked: pixel-measured contrast 0 of 789 text items below AA in dark and in light; test_site.py all passed.


## 21. Hero circles, ticker, motion and theme switch (2026-11-05, experiments only)

- Hero graphic: only the two big filled circles (and their gold overlap) were removed from `hero-studio.svg`. The construction lines, bezier anchors, dotted flow line and sparkles stay (Prm rejected a version that removed them).
- Marquee: four copies of the word list (three `aria-hidden`), 80s loop, so it never shows a gap even on wide screens. Hover/focus no longer pause it: focus stayed on the pause button after pressing play, so the strip never restarted. The pause button still stops every looping animation.
- Subtle motion: hero text and graphic rise in on load, the hero art drifts slowly, sparkles twinkle, section headings, stats, steps, why points, values and FAQ rows reveal on scroll with a small stagger, and the stats count up once. All of it stops with reduced motion; looping parts stop with the pause button.
- Light/dark switch: a small round moon/sun button (`#themeBtn`) after "Start a project" (next to the burger on phones). It sets `html[data-theme]` and remembers the choice in localStorage `gduxi-theme`; with no choice the site follows the device. Dark rules exist twice: inside `@media (prefers-color-scheme:dark)` guarded by `:not([data-theme="light"])`, and under `[data-theme="dark"]`. Edit both together.
- Favicons: `favicon.svg` (the logo mark) plus `favicon.ico` (16/32/48), `favicon-32.png`, `favicon-192.png`, `favicon-512.png` and a full-bleed `apple-touch-icon.png` (180, iOS rounds it), all rendered from the SVG. Linked from `index.html` and `admin/index.html`.
- Hero graphic (later): the mark is scaled to 0.8 around its centre so it sits fully inside the inner guide circle (r=104). Rejected tries: a 1.2x bigger mark, and shrinking the circle so it hid behind the mark. The phone outline is the same light 1px `#E2DEEC` stroke as the website window, not a dark frame.
- Theme button hover (purple border, small turn) only applies on devices that can hover (`@media (hover:hover)`), so it doesn't stick after a tap on phones.

## 22. Prototypes open inside the site (2026-11-05, experiments only)

Prm chose option 1 of three (embed / clickable screens / rebuild): the "Prototype →" buttons (cards and the screens pop-up) are now `<button data-proto="i">` that open `<dialog id="protoDlg">` with the live Figma prototype in an iframe. `embedUrl()` turns the project's `figma` URL into `https://embed.figma.com/proto/...&embed-host=gduxi-studio`; non-Figma URLs still open in a new tab. The pop-up has a shimmer until the iframe loads, an "Open in Figma ↗" fallback link, the sticky ✕, and clears the iframe on close.
- Visitors only see the prototype if each Figma file is shared as "Anyone with the link · can view" (still an open item).
- Not verified against real Figma: the cloud sandbox can't reach embed.figma.com, so tests stub it. Check on the Netlify preview.
- `tests/test_figma_links.py` now checks the embed URL and the Figma tab, and matches titles case-insensitively (the Title Case CSS had made the RS campaigns check fail). Both test files pass.

## 23. Audit and merge to main (2026-11-05)

Prm asked to merge `experiments` into main (the live site, https://gduxi.studio) after a full check, keeping the original safe. Backups of the old main (360f790): branches `backup/2026-11-04` and `backup/main-before-merge-2026-11-05`, plus /mnt/project-files/backups/2026-11-04/.
- SEO additions: canonical `https://gduxi.studio/`, absolute `og:image`, og:type/url/site_name, Twitter card, JSON-LD `ProfessionalService` (founders, email, area served), `robots.txt` (admin disallowed) and `sitemap.xml`. `netlify.toml` caches `/assets/*` for 7 days and marks `/admin/*` noindex.
- Fixes from Lighthouse: logo links and service cards no longer use an aria-label that differs from their visible text; founder photos and signatures lazy-load; the hero graphic is preloaded with high priority; the hero entrance animation starts at 1% opacity so it doesn't delay LCP.
- Results (local server, Lighthouse 12.2.1, 4 pages): Accessibility 100, Best practices 100, SEO 100 on desktop and phone; Performance 98–99 desktop, 79–81 phone. The phone score is held down by things the local server lacks (text compression, cache headers), which Netlify provides, so the live score should be higher. axe-core: 0 violations in 16 views (light and dark). Alt text: every image has alt (descriptive or empty for decorative). One h1 per page, no skipped heading levels. No broken local links. Pixel contrast: 0 of 821 text items below AA in light and dark.

## 24. Logo lockup alignment (2026-11-05, experiments only)

Prm asked for "STUDIO" to sit under the "DUX" of GDUXI. `.logo .st` is Inter 600 10px with 3.75px tracking, `padding-left:25.75px` and `margin-right:-3.75px`, so the STUDIO ink runs from the left edge of the D to the right edge of the X (measured 26.25–82.0px under D 26.25 and X 82.0). An earlier try that stretched it from G to I was rejected. Header, footer, phone menu and contact card share it. If the wordmark size changes, re-measure the letter positions rather than guessing.
