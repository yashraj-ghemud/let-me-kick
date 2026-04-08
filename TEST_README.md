# GHOST-KICKER Test Suite

## 🧪 About the Test Suite

The `test-ghost-kicker.sh` script validates the structure, syntax, and logic of `ghost-kicker.sh` without requiring actual hardware or root access. It performs comprehensive checks to ensure the script is properly written before deployment.

## 🚀 Running the Test Suite

### Linux/Termux:
```bash
chmod +x test-ghost-kicker.sh
./test-ghost-kicker.sh
```

### Windows (Git Bash/WSL):
```bash
bash test-ghost-kicker.sh
```

## 📋 Test Categories

### 1. **File Permissions Check**
- Verifies script file exists
- Checks file is readable
- Validates documentation files exist

### 2. **Bash Syntax Validation**
- Checks for valid bash syntax
- Detects syntax errors before runtime

### 3. **Script Structure Validation**
- Confirms all required functions exist
- Validates function definitions
- Checks proper function naming

### 4. **Trap Handler Validation**
- Verifies SIGINT trap is set
- Confirms cleanup handler is called

### 5. **Color Codes Validation**
- Checks all ANSI color codes are defined
- Validates color variable assignments

### 6. **Global Variables Validation**
- Confirms required global variables exist
- Validates variable assignments

### 7. **Menu Options Validation**
- Checks all 5 menu options are present
- Validates menu structure

### 8. **Aircrack-ng Commands Validation**
- Verifies all aircrack-ng commands are used
- Checks proper command syntax

### 9. **Smart Interval Validation**
- Confirms smart interval feature is implemented
- Validates configurable interval logic

### 10. **Auto-Target Feature Validation**
- Verifies CSV parsing logic
- Checks client selection by number
- Validates auto-target menu option

### 11. **Logging Validation**
- Confirms log file creation
- Validates CSV output format
- Checks scan result logging

### 12. **Cleanup Logic Validation**
- Verifies process killing logic
- Confirms network restoration
- Validates monitor mode disabling

### 13. **Comments Validation**
- Checks script has proper documentation
- Validates function comments
- Confirms description comments

### 14. **Root Check Validation**
- Verifies root privilege check
- Validates error messages

### 15. **Dependency Check Validation**
- Confirms aircrack-ng check
- Validates install instructions

## 📊 Test Output

The test suite provides:
- **Total Tests Run**: Number of tests executed
- **Tests Passed**: Number of successful tests
- **Tests Failed**: Number of failed tests
- **Pass/Fail Status**: Clear visual feedback

## ✅ Success Criteria

All tests should pass before using the script on actual hardware. If any test fails:
1. Review the failed test category
2. Check the corresponding section in `ghost-kicker.sh`
3. Fix the issue
4. Re-run the test suite

## ⚠️ Important Notes

- This test suite validates **structure only**, not actual functionality
- Actual functionality requires:
  - Root access
  - aircrack-ng suite installed
  - Wireless adapter with monitor mode support
  - Linux or Termux environment
- The test suite can run on any system with bash

## 🔧 Troubleshooting

### "bash: ./test-ghost-kicker.sh: Permission denied"
```bash
chmod +x test-ghost-kicker.sh
```

### "ghost-kicker.sh: No such file or directory"
- Ensure you're in the correct directory
- Check that `ghost-kicker.sh` exists in the same folder

### Test fails on "Bash Syntax Validation"
- Open `ghost-kicker.sh` and check for syntax errors
- Run `bash -n ghost-kicker.sh` to see specific errors

## 📝 Test Results Interpretation

### All Tests Passed ✅
- Script structure is valid
- Ready to deploy on Linux/Termux with proper hardware
- Proceed with actual testing on target system

### Some Tests Failed ❌
- Review failed test categories
- Fix identified issues in `ghost-kicker.sh`
- Re-run test suite until all pass

## 🎯 Next Steps After Passing Tests

1. **Install Dependencies** (if not already installed):
   ```bash
   sudo apt install aircrack-ng  # Linux
   pkg install aircrack-ng       # Termux
   ```

2. **Make Script Executable**:
   ```bash
   chmod +x ghost-kicker.sh
   ```

3. **Run with Root**:
   ```bash
   sudo ./ghost-kicker.sh       # Linux
   su && ./ghost-kicker.sh      # Termux
   ```

4. **Test on Hardware**:
   - Enable monitor mode
   - Scan networks
   - Test with your own network only

## 📄 License

This test suite is part of GHOST-KICKER v1.0. Use responsibly and ethically.
