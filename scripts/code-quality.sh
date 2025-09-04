#!/bin/bash
# Code quality tools for Zephyr development

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check code format
check_format() {
    print_status "Checking code format with clang-format..."
    
    # Find all C/C++ files
    files=$(find . -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.hpp" | grep -v build)
    
    if [ -z "$files" ]; then
        print_warning "No C/C++ files found to format"
        return 0
    fi
    
    format_issues=0
    for file in $files; do
        if ! clang-format --dry-run --Werror "$file" >/dev/null 2>&1; then
            print_error "Format issues in $file"
            format_issues=$((format_issues + 1))
        fi
    done
    
    if [ $format_issues -eq 0 ]; then
        print_status "All files are properly formatted ✓"
    else
        print_error "Found formatting issues in $format_issues files"
        echo "Run 'clang-format -i <file>' to fix formatting"
        return 1
    fi
}

# Function to run static analysis
run_static_analysis() {
    print_status "Running static analysis with cppcheck..."
    
    if [ ! -d "build" ]; then
        print_error "No build directory found. Run 'west build' first."
        return 1
    fi
    
    cppcheck --enable=all --suppress=missingIncludeSystem \
             --suppress=unusedFunction --suppress=unmatchedSuppression \
             --template="{file}:{line}: {severity}: {message}" \
             --std=c11 --platform=unix32 \
             -I build/zephyr/include/generated \
             -I /opt/zephyr-project/zephyr/include \
             src/ 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_status "Static analysis completed ✓"
    else
        print_error "Static analysis found issues"
        return 1
    fi
}

# Function to format code
format_code() {
    print_status "Formatting code with clang-format..."
    
    files=$(find . -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.hpp" | grep -v build)
    
    if [ -z "$files" ]; then
        print_warning "No C/C++ files found to format"
        return 0
    fi
    
    for file in $files; do
        clang-format -i "$file"
        echo "Formatted: $file"
    done
    
    print_status "Code formatting completed ✓"
}

# Function to setup pre-commit hooks
setup_precommit() {
    print_status "Setting up pre-commit hooks..."
    
    if [ ! -f ".pre-commit-config.yaml" ]; then
        print_error "No .pre-commit-config.yaml found"
        return 1
    fi
    
    pre-commit install
    print_status "Pre-commit hooks installed ✓"
}

# Main function
main() {
    case "$1" in
        "check")
            check_format
            run_static_analysis
            ;;
        "format")
            format_code
            ;;
        "setup")
            setup_precommit
            ;;
        "all")
            setup_precommit
            format_code
            check_format
            run_static_analysis
            ;;
        *)
            echo "Usage: $0 {check|format|setup|all}"
            echo ""
            echo "Commands:"
            echo "  check  - Check code formatting and run static analysis"
            echo "  format - Format all C/C++ files"
            echo "  setup  - Install pre-commit hooks"
            echo "  all    - Run setup, format, and check"
            exit 1
            ;;
    esac
}

main "$@"