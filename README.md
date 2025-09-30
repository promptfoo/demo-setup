## Interactive Kali + Promptfoo workflow

This simulates a fresh laptop: you first start a plain Kali container interactively, then push your SQLite DB and run the setup inside the container.

### Files

- `start-interactive.sh`: Starts a new Kali container interactively with host port mapping.
- `push-db-and-setup.sh`: Copies your local SQLite DB (defaults to `~/.promptfoo/promptfoo.db`) and `inside-setup.sh` into the running container, then runs the setup.
- `inside-setup.sh`: Runs inside container. Installs Node.js/npm/sqlite3, installs latest `promptfoo`, copies DB into `/root/.promptfoo/db.sqlite`, and starts `promptfoo view` on port 3000.

### Usage

1) Start an interactive container (in a new terminal window):

```bash
NAME=kali-promptfoo-int PORT=3000 ./start-interactive.sh
```

This lands you in a root shell inside the container. Leave it running.

2) In another terminal on the host, push your SQLite DB and run setup inside the container:

```bash
NAME=kali-promptfoo-int PORT=3000 ./push-db-and-setup.sh
```

By default it will copy `~/.promptfoo/promptfoo.db`. To override, pass a path:

```bash
NAME=kali-promptfoo-int PORT=3000 ./push-db-and-setup.sh /absolute/path/to/promptfoo.db
```

This installs dependencies and promptfoo inside the container and starts the UI.

3) Open your browser to:

```
http://localhost:3000
```

Notes:

- If you need to re-run setup, you can execute inside the container:

```bash
bash /root/incoming/inside-setup.sh --db /root/incoming/db.sqlite --port 3000 --host 0.0.0.0
```

- Logs are written to `/root/promptfoo-view.log` inside the container.


