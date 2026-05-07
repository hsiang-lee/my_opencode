---
name: qnx
description: QNX target system connection and deployment tool for RVC service debugging.
license: MIT
compatibility: opencode
---

# qnx - QNX Deployment & Debugging

## Architecture Overview

```
┌─────────────┐     adb      ┌─────────────┐   busybox telnet   ┌─────────────┐
│  Local Host │ ──────────►  │   Android   │ ─────────────────► │    QNX      │
│             │              │  (bridge)   │                    │  (target)   │
└─────────────┘              └─────────────┘                    └─────────────┘
                                    │
                                    │ busybox ftpput/ftpget
                                    ▼
```

**Important**: busybox commands run on **Android**, NOT on local host or QNX.

## Prerequisites

- ADB available on local host
- Android device accessible via ADB
- QNX credentials: `root` / `omo75A322@`
- QNX IP: `192.168.1.1`

## Interactive Connection (interactive_bash)

Use `interactive_bash` tool for QNX connection:

```
tmux_command: adb shell busybox telnet 192.168.1.1
```

After connection, login with credentials:
```
Username: root
Password: omo75A322@
```

## File Transfer

### Local → Android (via ADB)

```bash
adb push /path/to/local/file /data/local/tmp/target_file
```

### Android → QNX (via busybox FTP)

```bash
adb shell "busybox ftpput -u root -p omo75A322@ 192.168.1.1 /share/target_file /data/local/tmp/source_file"
```

### QNX → Android (via busybox FTP)

```bash
adb shell "busybox ftpget -u root -p omo75A322@ 192.168.1.1 /data/local/tmp/local_file /share/remote_file"
```

### Android → Local (via ADB pull)

```bash
adb pull /data/local/tmp/file /path/to/local/destination
```

## Deployment Workflow

### 1. Build Package

```bash
cd /root/rvc_service
cmake --preset qnx-release
cmake --build --preset qnx-release --target package
```

### 2. Push to Android

```bash
adb push build/rvc_service-*.tar.gz /data/local/tmp/rvc.tar.gz
```

### 3. Push to QNX

```bash
adb shell "busybox ftpput -u root -p omo75A322@ 192.168.1.1 /share/rvc_service.tar.gz /data/local/tmp/rvc.tar.gz"
```

### 4. Deploy on QNX (using interactive_bash)

Connect via interactive_bash, then:

```bash
cd /share
rm -rf rvc_service-*
tar xzf rvc_service.tar.gz
ls -la
```

### 5. Run Service

```bash
# Kill existing process (will ask for y/N confirmation)
slay rvc_service
# Type y to confirm

# Run service
./run_rvc.sh > /tmp/rvc.log 2>&1 &
```

### 6. View Logs

```bash
cat /tmp/rvc.log
```

## Collect Logs

```bash
# Push log to Android
adb shell "busybox ftpput -u root -p omo75A322@ 192.168.1.2 /data/local/tmp/rvc.log /tmp/rvc.log"

# Pull to local
adb pull /data/local/tmp/rvc.log ./
```

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `slay: Unable to find process` | Service not running | Skip slay, run directly |
| `tar: Can't restore time` | Filesystem permission | Ignore, files extracted OK |
| `ftpput: connection refused` | QNX FTP not running | Check QNX network config |
| `./run_rvc.sh: cannot execute` | Wrong directory | Use `cd /share/rvc_service-c62x-*` |

## Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `QNX_IP` | `192.168.1.1` | QNX target |
| `QNX_USER` | `root` | Username |
| `QNX_PASS` | `omo75A322@` | Password |
| `ANDROID_TMP` | `/data/local/tmp` | Android temp |

## Reference

- RVC Service: `/root/rvc_service`
- QNX Deploy Script: `run_rvc.sh` in deployed package
- Log Location: `/tmp/rvc.log` on QNX
