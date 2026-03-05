# Claude Skill: Architecture to Autonomy Blog Theme

Use this skill to convert a new article into a production-ready blog post HTML file for this site.

## Goal
- Generate a new post in `posts/<slug>.html` that matches the existing site theme.
- Preserve the original writing voice and meaning.
- Keep all provided images.

## Theme Reference Files
- Standard post theme reference:
  - `posts/leading-from-altitude-strategic-distance.html`
  - `posts/accelerating-ai-transformation-vmware-samir-roshan-vnoxc.html`
- Long-form/advanced visual reference:
  - `posts/agentic-enterprise-platform-stack.html`

## Non-Negotiable Rules
1. Do not rewrite the author's voice. Keep original text as-is except minor typo cleanup if explicitly requested.
2. Do not remove images.
3. Do not add public "Edit this post" links.
4. Do not add standalone static-page footers.
5. Keep navigation consistent:
   - Top: `Back to posts`
   - Bottom: `Back to all posts` + `Connect on LinkedIn`
6. Use these brand paths/links:
   - Logo: `../assets/a2a-logo.svg`
   - Back link: `../index.html#posts`
   - LinkedIn: `https://www.linkedin.com/in/samirroshan/`

## Required Page Structure
Use this structure and class names:
- `header.topbar`
- `section.hero`
- `section > .container > article`
- `.source` block (if republished from LinkedIn)
- `.bottom-nav` with two actions:
  - `Back to all posts`
  - `Connect on LinkedIn`

## Styling Contract
For regular posts, use the same style contract as standard reference posts:
- Fonts:
  - `"Space Grotesk", sans-serif`
  - `"IBM Plex Mono", monospace`
- Visual style:
  - Soft gradient background
  - Sticky top bar
  - Hero card with kicker/title/dek/meta pills
  - White article card with subtle border and shadow
  - Rounded pill action buttons at bottom

Do not introduce a new visual direction unless explicitly asked.

## Metadata Requirements
Set these fields in every new post:
- `<title>`: `<Post Title> | Architecture to Autonomy`
- `<meta name="description">`: concise summary from source
- Hero metadata pills:
  - `By Samir Roshan`
  - Absolute publication date (for example: `Published October 27, 2025`)
  - Read time estimate

## LinkedIn Republishing Pattern
If source is a LinkedIn article:
- Add kicker: `Republished from LinkedIn`
- Add source block at bottom:
  - `Originally published on LinkedIn on <DATE>.`
  - Link to original LinkedIn post

## File Naming
- Use a stable slug in lowercase with hyphens.
- Save as `posts/<slug>.html`.

## Quality Checklist
Before finalizing:
1. Page opens without layout break.
2. All images render.
3. Special characters are valid UTF-8 and not corrupted.
4. Bottom actions are present and aligned.
5. No `Edit this post` link appears publicly.
6. No static footer block appears.

## Optional: Add Post to Index
If requested, also add the new post card in `index.html` under the posts section with:
- Title
- Short excerpt
- Publication date
- Link to `posts/<slug>.html`

## Copy/Paste Prompt for Claude
Use this with the skill file attached:

```
Use the attached "Claude Skill: Architecture to Autonomy Blog Theme".

Create a new blog post HTML in our site theme from the content below.
Requirements:
- Preserve original writing.
- Keep all images.
- Use standard blog template style (topbar, hero card, article card, bottom nav).
- No public edit links.
- No static footer.
- Include LinkedIn source attribution block with original date and link.

Output:
1. Full HTML file content for posts/<slug>.html
2. Suggested slug
3. 1-line summary for index card
```

