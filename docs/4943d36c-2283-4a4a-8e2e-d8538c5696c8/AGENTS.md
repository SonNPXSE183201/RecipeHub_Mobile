<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.

## What Lovable manages

Rules outside this block are the project's own. Change the pieces below in
Lovable, not by hand. With the [Lovable MCP](https://mcp.lovable.dev)
connected, `send_message` asks Lovable to do it; otherwise ask the user to
use the editor.

- **Database.** Do not add or edit `supabase/migrations/` or `drizzle/`.
  Ask Lovable to change the schema.
- **Generated files.** Do not edit a file whose header says it is automatically
  generated.
- **AI gateway.** Keep model calls on Lovable's gateway, and keep
  `LOVABLE_API_KEY` out of browser code.
- **Connectors.** Lovable provides native connectors. `list_connectors` shows
  which are enabled; `add_connector` only returns the dashboard link. When a
  connector is enabled, calls go through the connector gateway and need
  `LOVABLE_API_KEY`. When Lovable does not provide one, users can bring their
  own key and store it in Secrets.
- **Secrets.** Lovable manages them. Do not put secret values in the repo.
<!-- LOVABLE:END -->

## Prototype architecture
- Keep illustrative catalogue data and pure search rules in a browser-safe module so the mobile wireflow can be tested without claiming backend integration.
- Keep work tabs mounted and detail/form overlays separate so in-session drafts, filters and scroll survive navigation; all send outcomes are explicitly simulated.
- Use the shared Motion screen stack for directional navigation and focus management; retain covered screens so nested SOP and practice references keep their scroll positions.
- Calculate practice time from timestamps rather than interval counts so background throttling cannot lose elapsed time; only explicit session recording adds a result.
- Keep all prototype writes in memory with explicit session-only acknowledgements; never connect or replace the real app's backend for UX reference work.
- Render recipe and SOP instructions through the shared browser-safe InstructionDocument; task-specific layout classes separate lookup, reading, learning and forms without altering their retained state.
- Store ebooklet document/block/word anchors in app session state and paginate against measured browser typography on viewport/font changes, so reflow and closing retain content position without persistent writes.
- Keep the handbook's four non-modal content panes mounted with one shared bottom navigation and in-module history; isolate book gestures above that navigation so drafts, reading anchors and scroll survive switches and dismissal reveals retained Home.
- Render ebooklet instructions in a dedicated paper document, leaving lookup/learning InstructionDocument layouts unchanged; rotate only a temporary paper layer over a stable underlying page, and gate sequential turns while direct jumps replace the current transition.
- Generate complete ebooklet PDFs in the browser with a bundled-on-demand PDF library and CDN-hosted Vietnamese font; validate all catalogue instructions before export and derive PDF counts from generated pages.
- Use the shared DataPicker for data-choice fields with a body-portal bottom sheet; integrate dismissal with the app history stack so Back closes only the picker and retained forms stay mounted.
