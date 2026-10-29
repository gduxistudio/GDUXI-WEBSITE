# GDUXI Studio website

The website for GDUXI Studio, a brand and digital design studio run by Navita Ramanand and Paramdeep Singh.

It is a static, single-page site (no build step) with four pages (Home, Work, Studio, Services & contact), an editing dashboard at `/admin`, and a contact form that emails the studio. Developers and AI assistants should read `CLAUDE.md` first.

## Look at it on your computer

```bash
python3 -m http.server 8000
```

Then open http://localhost:8000. (Opening `index.html` straight from the folder also works, using the built-in copy of the content.)

## Put it online with Netlify

1. In Netlify, choose **Add new project → Import an existing project → GitHub**, and pick `paramzgraphic-arch/gduxi-website`.
2. Leave **Build command** empty and set **Publish directory** to `.` (the `netlify.toml` file already says this).
3. Deploy. Netlify gives you a `*.netlify.app` address; you can add your own domain under **Domain management**.

## Turn on the dashboard (`/admin`)

The dashboard lets either founder change text, projects, photos and the FAQ without touching code. Saving publishes straight away.

1. On GitHub, go to **Settings → Developer settings → OAuth Apps → New OAuth App**.
   - Homepage URL: your Netlify address
   - Authorization callback URL: `https://api.netlify.com/auth/done`
2. Copy the **Client ID** and generate a **Client secret**.
3. In Netlify, open **Project configuration → Access & security → OAuth → Install provider → GitHub**, and paste both values.
4. Visit `https://<your-site>/admin`, sign in with GitHub, and edit. Each founder needs write access to the GitHub repository.

To try the dashboard on your own computer without logging in: run `npx decap-server` in this folder, start the local server above, and open http://localhost:8000/admin.

## Turn on the contact form

The form sends through [FormSubmit](https://formsubmit.co) to the email in **Contact & footer** (currently gduxistudio@gmail.com).

1. Open the live site and send one test message from the form.
2. FormSubmit emails gduxistudio@gmail.com an **Activate form** link. Click it.
3. From then on, messages arrive in that inbox. Until it is activated, visitors see a friendly fallback with "Open my email app" and "Send with Gmail" buttons, so no enquiry is lost.

## Make the case studies viewable

Every project card opens a Figma file. In Figma, set each of those files to **Share → Anyone with the link → can view**, or visitors will see a "request access" screen.

## Folder guide

| Path | What it is |
| --- | --- |
| `index.html` | The whole site: page, styles and script |
| `content/*.json` | All the words, projects and photos (the dashboard edits these) |
| `assets/img/` | Images exported from the Figma file |
| `assets/uploads/` | Images uploaded through the dashboard |
| `admin/` | The Decap CMS dashboard |
| `tools/` | Helper scripts (see `CLAUDE.md`) |
| `tests/` | Automated click-through tests |
