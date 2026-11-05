# Tamil Nadu Election 2026 dashboard

A terminal-style election dashboard in two versions: the original shell TUI in `cli/` and a matching browser interface in `web/`.

> **Data status:** The original Election Commission endpoint currently returns 404. The web preview uses simulated demo data and changes it every five seconds by default; it does not connect to the endpoint. Demo figures are not election results. The CLI relies on that endpoint and will not show results while it is unavailable. Alliance groupings follow the original CLI and are not an official classification.

## Web preview

Visit the [GitHub Pages dashboard](https://ebinesh25.github.io/tn-election-2026-updateTUI/). To run it locally, clone the repository and start a static server:

```sh
git clone https://github.com/ebinesh25/tn-election-2026-updateTUI.git
cd tn-election-2026-updateTUI
python3 -m http.server 8000 --directory web
```

Open <http://localhost:8000>. No npm installation or build is needed. Use the buttons or `r`, `+`, and `-` to refresh or change the interval. Each refresh simulates a seat moving between parties while keeping the total at 234; figures are generated locally in each browser.

## CLI installation and use

Requires Bash, `curl`, `jq`, `tput` (ncurses), and a terminal. After cloning as above:

```sh
chmod +x cli/tn-election.sh
./cli/tn-election.sh
```

Press `q` to quit, `r` to refresh, `+` to refresh faster, and `-` to refresh more slowly. For example, install `jq` on Debian/Ubuntu with `sudo apt install jq` or on macOS with `brew install jq`.

## Deployment

The GitHub Actions workflow in `.github/workflows/pages.yml` publishes the `web/` folder on pushes to `main`. In repository **Settings → Pages**, set the build and deployment source to **GitHub Actions**. The site is static; it does not proxy the election API.

<img width="1918" height="1047" alt="Original terminal dashboard" src="https://github.com/user-attachments/assets/ddd3f716-5259-4831-a98f-b822c4093eb7" />
