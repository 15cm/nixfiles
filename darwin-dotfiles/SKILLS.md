# Darwin Dotfiles Management & Restoration Playbook
This playbook serves as the authoritative guide ("skill") for applying, updating, and restoring your custom Darwin macOS dotfiles.

---

## 📂 Workspace Directory Mapping
The root of the `darwin-dotfiles` repository directly corresponds to your system's Home directory (`$HOME/` or `~/`). All configurations are structured to mirror their final system destination.

---

## ⚙️ Application Rules & Methods
Different components of these dotfiles require distinct installation methods due to macOS-specific behaviors (such as preference caching and application import models). Follow these explicit guidelines:

| Component | Dotfiles Source Path | System Target Path | Method | Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Zsh Config** | `/.zshrc` | `~/.zshrc` | **Symlink** | Core shell logic; updates should propagate instantly. |
| **Zim Config** | `/.zimrc` | `~/.zimrc` | **Symlink** | Direct package manager inputs for Zimfw. |
| **Tmux Config** | `/.config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` | **Symlink** | Instantly reloadable terminal multiplexer setup. |
| **Preference Library** | `/Library/Preferences/` | `~/Library/Preferences/` | **Copy** | macOS caches preference plist files via the `cfprefsd` daemon. Symlinking plists frequently breaks preference updates or results in files being overwritten. |
| **Alfred Prefs** | `/app-export/Alfred.alfredpreferences` | `~/Library/Application Support/Alfred/Alfred.alfredpreferences` | **Copy/Sync** | Contains your Alfred workflows, snippets, and theme settings. |
| **Application Exports** | `/app-export/` | *Manual Import* | **App Import** | App settings (e.g., iStat Menus) must be applied manually through the app's built-in "Import Settings" menus. |

---

## 🚀 How to Apply (Restoration Guide)

### Step 1: Establish Shell Symlinks
Your `.zshrc` is designed to act as the automatic orchestrator. To bootstrap the entire environment, simply link the primary `.zshrc` first:

```bash
# 1. Link primary Zsh configuration
rm -f ~/.zshrc
ln -s ~/nixfiles/darwin-dotfiles/.zshrc ~/.zshrc

# 2. Trigger the auto-symlink manager
source ~/.zshrc
```

The shell will automatically hook the remaining Zsh (`.zimrc`) and Tmux (`.config/tmux/tmux.conf`) symlinks into place!

### Step 2: Copy macOS Preference Plists
macOS application preferences (like Amethyst) must be copied directly into your Library to avoid cache conflicts:

```bash
# Copy Amethyst plist to system preferences
cp ~/nixfiles/darwin-dotfiles/Library/Preferences/com.amethyst.Amethyst.plist ~/Library/Preferences/com.amethyst.Amethyst.plist

# Reload preferences daemon (to flush the cache and apply immediately)
defaults read com.amethyst.Amethyst
```

### Step 3: Import Application Settings
For tools with proprietary export formats stored in `app-export/`:
1. **iStat Menus**: Open **iStat Menus** $\rightarrow$ click **Settings Dropdown** (bottom left) $\rightarrow$ select **Install Settings...** $\rightarrow$ choose `~/nixfiles/darwin-dotfiles/app-export/iStat Menus Settings.ismp`.
2. **Alfred Preferences**: Copy the preferences directory back to Alfred's support folder:
   ```bash
   mkdir -p "~/Library/Application Support/Alfred"
   cp -R ~/nixfiles/darwin-dotfiles/app-export/Alfred.alfredpreferences "~/Library/Application Support/Alfred/"
   ```
   Then open **Alfred Preferences** $\rightarrow$ select the **Advanced** tab $\rightarrow$ click **Set Preference Folder...** $\rightarrow$ select `~/Library/Application Support/Alfred/Alfred.alfredpreferences`.
