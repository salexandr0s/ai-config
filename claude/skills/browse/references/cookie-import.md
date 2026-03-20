# Cookie Import Guide

## Supported Browsers

The browse daemon can import cookies from Chrome-based browsers installed on macOS:

- **Chrome** — `~/Library/Application Support/Google/Chrome/Default/Cookies`
- **Arc** — `~/Library/Application Support/Arc/User Data/Default/Cookies`
- **Brave** — `~/Library/Application Support/BraveSoftware/Brave-Browser/Default/Cookies`
- **Edge** — `~/Library/Application Support/Microsoft Edge/Default/Cookies`

## How It Works

1. Reads the SQLite cookie database directly
2. Imports cookies into the Playwright browser context
3. Cookies persist for the duration of the browse session

## Limitations

- Chrome-based browsers encrypt cookie values using macOS Keychain
- The raw SQLite values may not include encrypted session cookies
- For full cookie access, export cookies from your browser using an extension
- Only reads cookies — never modifies the source browser's data

## Usage

Cookie import is available programmatically through the browse daemon API. The `/browse` skill handles this automatically when needed.

## Security

- Cookie databases are read in-process only (no temp files)
- Imported cookies stay within the Playwright browser context
- Cookies are not persisted to disk by the browse daemon
- The daemon runs on localhost with token auth
