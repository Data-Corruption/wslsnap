# wslsnap

A PowerShell script to manage snapshots of your WSL install. I was working on something that installs other tools, testing it was a little tedious so i made this to help.

### Usage

1. Have Windows 10 or later with PowerShell and WSL installed
2. You'll probs need to run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`
3. Download `wslsnap.ps1` and open PowerShell as an Administrator in the script's directory.
4. Run `.\wslsnap.ps1 <command>`

- Snapshots are stored in the script's directory under /snapshots.
- It has basic error handling but if you are doing weird wild stuff be careful.
- Add the script directory to your PATH for global access. Hope it helps <3

### Commands
- `list`: List snapshots
- `create <snapshot-name>`: Create a snapshot
- `remove <snapshot-name>`: Remove a snapshot
- `restore <snapshot-name>`: Restore a snapshot

### Planned Features
- --force, -f flag for the restore command
- tab completion for remove and restore commands