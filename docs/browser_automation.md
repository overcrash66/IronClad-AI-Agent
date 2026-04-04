# Browser Automation (Playwright)

IronClad includes built-in web scraping and visual browser interaction capabilities powered by **Playwright**. The current runtime exposes text scraping and visual page visiting, which covers the common cases of reading a page and showing a page to the user.

## Prerequisites

Before using the browser tools, you must install Playwright and its browser binaries on your host system:

```bash
# Install the Playwright browser binaries
npx playwright install
```

If you are running IronClad inside a container, ensure your `Dockerfile` includes the necessary Playwright installations.

## Features & Tools

IronClad currently exposes two browser tools to the agent:

### 1. `browser_scrape`

- **Purpose**: Extracts raw text representation of a webpage.
- **Workflow**: 
  - Launches a headless Chromium instance.
  - Navigates to the specified URL.
  - Waits for the page and network connections to fully load.
  - Evaluates JavaScript to remove unnecessary elements (like scripts, styles, SVG).
  - Extracts the text content and returns it to the agent.
- **Use Case**: Best for simple information retrieval, summarizing articles, or retrieving documentation.

### 2. `browser_visit`

- **Purpose**: Opens a page visually in a real browser window.
- **Workflow**:
  - Launches or reuses a Playwright-backed Chromium instance.
  - Navigates to the requested URL.
  - Keeps the page open so the user can inspect it visually.
- **Use Case**: "Show me this website", opening a video or dashboard, or visually confirming the rendered page.

`browser_visit` requires `[browser] headless = false`. When headless mode is enabled, the visit request is rejected because there is no visible browser window to show.

## Configuration

Browser behavior can be tweaked in `settings.toml`:

```toml
[browser]
# Set to false to see the browser window open (useful for debugging)
headless = true 
```

## Security & Best Practices

- **Sandboxing**: Unlike shell commands which run within the `[sandbox]` configuration, browser tools run on the host via Playwright. Keep this in mind if evaluating untrusted websites.
- **Timeout Restrictions**: Complex pages might cause the agent's QA loop or the Playwright engine to timeout. Ensure `timeout_secs` in `[sandbox]` and `loop_timeout_secs` in `[llm]` are sufficiently high for web-scraping tasks.
- **Governor Policies**: Instruct the agent via explicit system prompts if you want to prevent it from scraping or visiting specific domains.
