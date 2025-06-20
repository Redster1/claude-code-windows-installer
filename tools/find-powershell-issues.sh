#!/bin/bash
# PowerShell Issue Hunter - Finds problematic patterns that cause NSIS execution errors

echo "🔍 PowerShell Issue Hunter - Scanning for problematic patterns..."
echo "=================================================================="

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ISSUES_FOUND=0

# Function to check files and report issues
check_pattern() {
    local pattern="$1"
    local description="$2"
    local files="$3"
    
    echo -e "\n${BLUE}🔍 Checking for: $description${NC}"
    
    if command -v rg >/dev/null 2>&1; then
        results=$(rg "$pattern" $files --line-number --color=never 2>/dev/null || true)
    else
        results=$(grep -n "$pattern" $files 2>/dev/null || true)
    fi
    
    if [ -n "$results" ]; then
        echo -e "${RED}❌ FOUND ISSUES:${NC}"
        echo "$results" | while read line; do
            echo -e "  ${YELLOW}$line${NC}"
        done
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        return 1
    else
        echo -e "${GREEN}✅ No issues found${NC}"
        return 0
    fi
}

echo -e "${BLUE}Target files:${NC}"
find src/ -name "*.psm1" -o -name "*.ps1" -o -name "*.nsi" | while read file; do
    echo "  📄 $file"
done

# 1. Check for Write-Error in NSIS embedded commands
echo -e "\n${BLUE}==================== CRITICAL CHECKS ====================${NC}"

check_pattern 'Write-Error' "Write-Error calls (causes restricted chars error)" "src/installer/*.nsi src/scripts/powershell/*.psm1"

# 2. Check for Write-Host usage
check_pattern 'Write-Host' "Write-Host usage (NSIS compatibility issues)" "src/scripts/powershell/*.psm1"

# 3. Check for problematic characters in function names
echo -e "\n${BLUE}🔍 Checking for: Problematic characters in function names${NC}"
if command -v rg >/dev/null 2>&1; then
    func_results=$(rg 'function\s+[^{]*[\#\(\)\{\}\[\]\&\*\?\;\"|\<\>]+' src/scripts/powershell/ --line-number --color=never 2>/dev/null || true)
else
    func_results=$(grep -n 'function.*[#(){}[\]&*?;"|<>]' src/scripts/powershell/*.psm1 2>/dev/null || true)
fi

if [ -n "$func_results" ]; then
    echo -e "${RED}❌ FOUND ISSUES:${NC}"
    echo "$func_results" | while read line; do
        echo -e "  ${YELLOW}$line${NC}"
    done
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✅ No issues found${NC}"
fi

# 4. Check for problematic PowerShell constructs in NSIS
echo -e "\n${BLUE}==================== NSIS INTEGRATION CHECKS ====================${NC}"

check_pattern '\$\(' "Command substitution \$() in NSIS PowerShell commands" "src/installer/*.nsi"

check_pattern '\|\|' "Logical OR operators || in NSIS PowerShell commands" "src/installer/*.nsi"

check_pattern '\&\&' "Logical AND operators && in NSIS PowerShell commands" "src/installer/*.nsi"

# 5. Check for here-strings in NSIS
check_pattern '@["'"'"']' "Here-strings in NSIS PowerShell commands" "src/installer/*.nsi"

# 6. Check for complex PowerShell expressions in NSIS
echo -e "\n${BLUE}🔍 Checking for: Complex PowerShell expressions in NSIS${NC}"
if command -v rg >/dev/null 2>&1; then
    complex_results=$(rg 'nsExec::ExecToStack.*powershell.*-Command.*\{.*\}' src/installer/ --line-number --color=never 2>/dev/null || true)
else
    complex_results=$(grep -n 'nsExec::ExecToStack.*powershell.*-Command.*{.*}' src/installer/*.nsi 2>/dev/null || true)
fi

if [ -n "$complex_results" ]; then
    echo -e "${RED}❌ FOUND ISSUES:${NC}"
    echo "$complex_results" | while read line; do
        echo -e "  ${YELLOW}$line${NC}"
    done
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✅ No issues found${NC}"
fi

# 7. Check for unescaped quotes in PowerShell commands
echo -e "\n${BLUE}==================== ESCAPING CHECKS ====================${NC}"

check_pattern 'powershell.*-Command.*[^\\]".*[^\\]"' "Unescaped quotes in PowerShell commands" "src/installer/*.nsi"

# 8. Check for PowerShell variables that might conflict with NSIS
check_pattern '\$result\.' "PowerShell object property access in NSIS" "src/installer/*.nsi"

# 9. Check for empty catch blocks (linting issue)
echo -e "\n${BLUE}==================== CODE QUALITY CHECKS ====================${NC}"

echo -e "\n${BLUE}🔍 Checking for: Empty catch blocks${NC}"
if command -v rg >/dev/null 2>&1; then
    catch_results=$(rg 'catch\s*\{\s*#[^}]*\}' src/scripts/powershell/ --line-number --color=never -U 2>/dev/null || true)
else
    catch_results=$(grep -n -A 3 'catch {' src/scripts/powershell/*.psm1 | grep -B 1 -A 1 "^\s*#" | grep "catch {" 2>/dev/null || true)
fi

if [ -n "$catch_results" ]; then
    echo -e "${YELLOW}⚠️  FOUND WARNINGS:${NC}"
    echo "$catch_results" | while read line; do
        echo -e "  ${YELLOW}$line${NC}"
    done
else
    echo -e "${GREEN}✅ No issues found${NC}"
fi

# 10. Check for problematic module exports
check_pattern "Export-ModuleMember.*[\#\(\)\{\}\[\]\&\*\?\;\"|\<\>]" "Problematic characters in module exports" "src/scripts/powershell/*.psm1"

# Summary
echo -e "\n${BLUE}==================== SUMMARY ====================${NC}"
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}🎉 No critical PowerShell issues found!${NC}"
    echo -e "${GREEN}The codebase appears to be free of known PowerShell/NSIS integration problems.${NC}"
    exit 0
else
    echo -e "${RED}❌ Found $ISSUES_FOUND category(ies) of issues that need to be fixed.${NC}"
    echo -e "${YELLOW}These issues may cause 'restricted characters' or other PowerShell execution errors.${NC}"
    exit 1
fi