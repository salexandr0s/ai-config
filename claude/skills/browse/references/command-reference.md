# Browse Command Reference

## Navigation

| Command   | Args          | Description          |
|-----------|---------------|----------------------|
| `goto`    | `--url URL`   | Navigate to URL      |
| `back`    | —             | Navigate back        |
| `forward` | —             | Navigate forward     |
| `reload`  | —             | Reload page          |
| `url`     | —             | Get current URL      |

## Reading

| Command         | Args                    | Description               |
|-----------------|-------------------------|---------------------------|
| `text`          | `--selector SEL`        | Get text content          |
| `html`          | `--selector SEL`        | Get HTML content          |
| `links`         | —                       | List all links            |
| `forms`         | —                       | List forms and fields     |
| `accessibility` | —                       | Raw accessibility tree    |

## Interaction

| Command  | Args                            | Description              |
|----------|---------------------------------|--------------------------|
| `click`  | `--selector SEL`                | Click element            |
| `fill`   | `--selector SEL --value VAL`    | Fill form field          |
| `select` | `--selector SEL --value VAL`    | Select dropdown option   |
| `hover`  | `--selector SEL`                | Hover over element       |
| `type`   | `--selector SEL --text TXT`     | Type text keystroke-by-keystroke |
| `press`  | `--key KEY`                     | Press keyboard key       |
| `scroll` | `--direction DIR --amount PX`   | Scroll page              |
| `wait`   | `--selector SEL --timeout MS`   | Wait for element/timeout |

## Inspection

| Command   | Args                    | Description              |
|-----------|-------------------------|--------------------------|
| `js`      | `--expression EXPR`     | Execute JavaScript       |
| `console` | —                       | Get console messages     |
| `cookies` | —                       | Get page cookies         |
| `storage` | —                       | Get localStorage         |

## Visual

| Command      | Args                          | Description          |
|--------------|-------------------------------|----------------------|
| `screenshot` | `--path PATH --fullPage BOOL` | Take screenshot      |
| `pdf`        | `--path PATH`                 | Save as PDF          |

## Snapshot

| Command    | Args                                     | Description              |
|------------|------------------------------------------|--------------------------|
| `snapshot` | `--compact --depth N --interactive BOOL` | Accessibility tree + refs |

## Tabs

| Command    | Args        | Description      |
|------------|-------------|------------------|
| `tabs`     | —           | List open tabs   |
| `newtab`   | `--url URL` | Open new tab     |
| `closetab` | —           | Close current tab |

## Meta

| Command  | Args | Description          |
|----------|------|----------------------|
| `status` | —    | Browser/page status  |
