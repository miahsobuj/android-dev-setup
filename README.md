# Android Development Environment Setup

Professional setup scripts for Android development on **aarch64/arm64** Linux with **native build-tools** (no QEMU needed).

## Features

- Native aarch64 Android SDK build-tools (lzhiyong + HomuHomu builds)
- OpenJDK 17 installation
- Gradle 8.7 setup
- Automated environment configuration
- Sample app for verification

## Quick Start

```bash
# Clone the repo
git clone https://github.com/miahsobuj/android-dev-setup.git
cd android-dev-setup

# Run setup (interactive)
./scripts/setup.sh

# Or with options
./scripts/setup.sh --dir ~/android-dev --yes
```

## Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-d, --dir DIR` | Installation directory (default: ~/android-dev) |
| `-y, --yes` | Skip confirmation prompts |
| `-c, --clean` | Clean existing installation |
| `-v, --verify` | Verify current installation |

## After Setup

```bash
# Add to your shell
source ~/.bashrc.android

# Build sample app
cd sample-app
./gradlew assembleDebug
```

## Project Structure

```
android-dev-setup/
├── scripts/
│   └── setup.sh           # Main setup script
├── config/
│   ├── gradle.properties   # Default Gradle config
│   ├── local.properties   # SDK path config
│   └── gitignore          # Android gitignore
├── sample-app/
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/main/
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   └── gradle.properties
└── .github/
    └── workflows/
        └── verify.yml     # CI verification
```

## Architecture Support

| Architecture | Build Tools | Status |
|-------------|-------------|--------|
| aarch64/arm64 | Native | ✅ Working |
| x86_64 | Official | ✅ Official SDK |

## Sources

- **lzhiyong/android-sdk-tools**: https://github.com/lzhiyong/android-sdk-tools/releases
- **HomuHomu833/android-sdk-custom**: https://gist.github.com/DesktopECHO/a35f0fb2cedbd699a8103b20dbd3c53f

## License

MIT
