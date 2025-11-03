# Windows Dev Box Setup

This guide walks through provisioning a Windows development VM in the cloud so you can exercise the Windows input pipeline locally (including the prompt helpers and `RawInputProvider`).

## 1. Provision the VM

You can use any provider; the steps below assume **Azure** because it offers hourly billing and baked-in RDP/SSH.

1. Open the [Azure Portal](https://portal.azure.com/) and create a **Windows 11 Pro** or **Windows Server 2022** VM.
2. Choose a VM size with at least **2 vCPUs / 4 GB RAM** (e.g., `Standard_B2ms`) so the Crystal compiler has room to run.
3. Configure networking:
   - Allow inbound **RDP (3389)** for graphical access.
   - Allow inbound **SSH (22)** if you prefer terminal workflow (available on Windows Server 2022+).
4. Generate an SSH key pair or use a password (SSH keys recommended).
5. Finish creation and note the public IP address.

> Tip: To keep costs down, enable auto-shutdown in the portal or script `az vm deallocate` when you're done.

## 2. Initial configuration

1. Remote in via RDP or SSH (`ssh username@YOUR_VM_IP`).
2. Update the system:
   - **Windows Update** (Settings → Windows Update).
   - Optional: Install [Chocolatey](https://chocolatey.org/install) for package management.
3. Install Crystal and build tools:
   ```powershell
   choco install -y crystal mingw git
   ```
4. Reboot if the installer prompts you.

## 3. Clone and prepare the repo

```powershell
git clone https://github.com/dsisnero/terminal.git
cd terminal
shards install
```

If `shards` is not on your PATH, add Crystal’s `bin` folder (e.g., `C:\ProgramData\chocolatey\lib\Crystal\bin`) to the environment and open a new shell.

## 4. Verify the Windows pipeline

Run the full spec suite (includes the Windows key-map checks):

```powershell
crystal spec
```

To focus on Windows input behaviour, you can run a subset:

```powershell
crystal spec spec/prompts_spec.cr spec/windows_key_map_spec.cr
```

While you have the VM, experiment with the prompt helpers directly:

```powershell
crystal eval 'require "./src/terminal/prompts"; puts Terminal::Prompts.password("Password:")'
```

## 5. Optional: SSH-only workflow

If you prefer to stay in the terminal:

1. Install the [OpenSSH Server feature](https://learn.microsoft.com/windows-server/administration/openssh/openssh_install_firstuse) on Windows.
2. Use VS Code Remote SSH or plain `ssh` to connect.
3. Run your usual shell-based workflow (Git, Crystal, etc.).

## 6. Tear down

When finished, deallocate or delete the VM to avoid charges. In Azure:

```bash
az vm deallocate --resource-group YOUR_GROUP --name YOUR_VM
```

You now have a reproducible path to test Windows-specific behaviour without leaving macOS.
