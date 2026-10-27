# Laptop Diagnostic Tool 🖥️

A PowerShell-based tool that helps Windows users collect system information and identify potential laptop issues.

## ✨ Features

- 💻 Hardware and system specifications
- 🔋 Battery health and capacity report
- 💾 Disk and storage information
- ⚠️ Windows system event errors
- 🧩 Installed drivers and applications
- 🔐 Windows activation and security status
- 📄 Diagnostic report generation

## 🛠️ Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or compatible PowerShell version
- Permission to access the system information being collected

## 🚀 How to Use

### Step 1: Download the script

1. Open this repository on GitHub.
2. Open `Laptop_Diagnostic_Collector.ps1`.
3. Click **Raw**, then use your browser's **Save** option to save the file to your computer.

### Step 2: Open PowerShell

1. Open the folder where you saved the script.
2. Open PowerShell or Windows Terminal.
3. Navigate to the folder containing the script. For example:

   ```powershell
   cd "$HOME\Downloads"
   ```

### Step 3: Run the diagnostic tool

Run the following commands in PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Laptop_Diagnostic_Collector.ps1
```

The execution policy change applies only to the current PowerShell session. Review the script before running it, and do not run scripts from sources you do not trust.

If Windows blocks the script or reports an error, read the message before changing security settings.

### Step 4: Review the reports

Allow the script to finish and check the output location or instructions displayed by the script. Open the generated diagnostic report to review your system information and any potential issues.

### Step 5: Share results safely

Before sharing a report publicly, check it for personal information such as usernames, device names, network details, file paths, and other sensitive information. You can take help of AI to analyze laptop report.

## ⚠️ Important Notes

- This tool collects diagnostic information; it does not guarantee detection of every hardware or software problem.
- A disk marked "Healthy" does not necessarily rule out hardware failure.
- Back up important data before attempting disk repairs.
- Do not publish personal diagnostic reports or sensitive system information in a public repository.
- This tool is provided for informational and troubleshooting purposes.

## 🤝 Contributions

Suggestions, bug reports, and improvements are welcome. Please open an issue or submit a pull request.

## 📜 License

A license has not yet been specified. Please check the repository's license before redistributing or modifying this project.
