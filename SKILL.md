---
name: bookmark
description: Turn the text after /bookmark into a polished, self-contained local HTML page, save it durably, and publish it under Edge Favorites bar/Imported through the existing Edge bookmarks companion extension. Use only when the user invokes /bookmark or explicitly asks to turn supplied context into an HTML bookmark. This is a general content-capture skill, not a learning-guide or learn-with-bookmarks workflow.
---

# Bookmark

Turn arbitrary context into one durable HTML page and add it to Microsoft Edge.

Invoke as:

```text
/bookmark <context, request, pasted material, or URL>
```

Everything after `/bookmark` is the request and source context. Do not route this
through `learn-with-bookmarks`, inherit its mandatory diagrams, generate a
learning bookmark tree, or create its manifest/import artifacts.

## Routing and context resolution

- `/bookmark` has exact-command precedence over every learning, documentation,
  and bookmark-related workflow. Invoke this skill immediately; never invoke
  `learn-with-bookmarks` for a `/bookmark` request.
- Resolve conversational references before creating the artifact. In particular,
  `/bookmark your last response` means the immediately preceding substantive
  assistant response, including the user question needed to understand it. It
  does not mean the literal command text.
- A bookmark request is an execution request, not a request for an
  acknowledgement. Do not answer with "bookmarked", "saved", "published", or any
  equivalent success-shaped wording until the HTML exists and the Edge companion
  has returned structured `ok: true`.
- If creation or publication cannot be completed, report the exact failed step
  and preserve any HTML already created. Never convert a failed or skipped
  execution into a conversational acknowledgement.

## Required outcome

1. Understand and complete the request in the supplied context. Research current
   facts or inspect referenced local/repository material only when needed.
2. Create one polished, self-contained `.html` file containing the useful result,
   not a transcript of the conversation or a dump of the prompt.
3. Save it under:

   ```text
   C:\Users\<user>\OneDrive - Microsoft\Documents\Bookmarks\<slug>\<slug>.html
   ```

   If that OneDrive Documents directory is unavailable, use:

   ```text
   C:\Users\<user>\Documents\Bookmarks\<slug>\<slug>.html
   ```

4. Publish it through the existing Edge companion extension to:

   ```text
   Favorites bar
     Imported
       <Title>.html
   ```

   Publish the HTML as one direct favorite under `Imported`. Do not create a
   per-bookmark folder.

5. Require a successful structured companion result. Never claim the bookmark
   was published merely because the HTML or command file was created.

## Content rules

- Preserve the supplied source text and its formatting structure exactly by
  default. Do not rewrite, summarize, reorder, correct, expand, contract, or
  otherwise reformat the content unless the user explicitly requests a change.
  HTML conversion may change only the representation needed to render the same
  headings, paragraphs, lists, tables, code blocks, emphasis, links, and spacing
  faithfully.
- Derive a concise human-readable title from the request.
- Derive a stable lowercase kebab-case slug. Reuse the same folder for the same
  subject so rerunning the command updates the bookmark rather than multiplying it.
- Make the page useful offline: embed CSS and JavaScript; do not require Mermaid,
  a CDN, web fonts, or a local server.
- Use semantic HTML, responsive layout, accessible colors, keyboard-visible focus,
  and print styles.
- Prefer a strong document structure: title, short summary, clear sections,
  tables or callouts where they improve comprehension, and source links when used.
- Match the artifact to the request. A checklist should look like a checklist; a
  comparison should emphasize a comparison; a technical explanation may include
  lightweight CSS/SVG diagrams only when they add value.
- Preserve important code, commands, URLs, constraints, and attribution from the
  supplied context. HTML-encode untrusted or pasted content.
- Distinguish verified facts from assumptions. Do not invent citations or links.
- Do not add learning-guide boilerplate, mandatory architecture/sequence/data-flow
  diagrams, telemetry links, or repository bookmark trees unless the user asks.

## Safe file behavior

- Keep durable artifacts out of `%TEMP%`, `.copilot\session-state`, repository
  source folders, Downloads, and attachment staging folders.
- Before replacing an existing HTML file, read it and preserve useful content
  unless the request clearly asks for replacement.
- Do not modify browser profile files. Never write Edge's Chromium `Bookmarks`
  file directly.
- The generated companion command may live beside the HTML as
  `<slug>-edge-command.json`; it is operational metadata, not user content.

## Publish

After creating and validating the HTML, run:

```powershell
& "$env:USERPROFILE\.copilot\skills\bookmark\scripts\Publish-Bookmark.ps1" `
  -HtmlPath "<absolute-html-path>" `
  -Title "<bookmark-title>"
```

The publisher uses the existing companion extension ID
`bcnnjcbahmgdcieaelpellgemkkgjgcg` and Edge's official bookmarks API. It upserts
one same-named HTML favorite directly under `Favorites bar\Imported`, replacing
any older bookmark-skill folder or favorite with that name.

If publication fails, keep the HTML and report the exact failure. Do not silently
fall back to direct profile editing.

## Validation

Before publishing:

- confirm the HTML file exists in the durable bookmark location;
- confirm it has a non-empty `<title>`, one `<h1>`, UTF-8 metadata, and no remote
  runtime dependency required to render the core page;
- open or inspect the page enough to catch malformed, clipped, or unreadable
  output;
- confirm every local link points to its intended absolute file URI and every web
  source link is absolute.

After publishing, require `ok: true` from the companion and report the HTML path
and Edge destination concisely.

Before finishing, apply this completion gate:

1. The durable HTML path exists.
2. `Publish-Bookmark.ps1` was actually invoked for that path and title.
3. Its returned `CompanionResult.ok` is exactly `true`.

If any condition is false or unknown, publication is incomplete and must not be
reported as successful.
