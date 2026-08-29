#!/bin/bash
set -e

# Automatically resolve the top-level Git repository root
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
cd "$GIT_ROOT"

# Path to Terraform lab directory relative to git root
LAB_PATH="Week1/Lab2"

# Default commit message if none provided
COMMIT_MSG="${1:-Update Terraform infrastructure and GitHub Actions workflows}"

# Get current branch name
BRANCH=$(git branch --show-current)

if [ -z "$BRANCH" ]; then
    echo "Error: Not a git repository or no active branch found."
    exit 1
fi

echo ""
echo "========================================="
echo " LEVEL 1: PRE-PUSH TERRAFORM CHECKS"
echo "========================================="

echo "[1/3] Checking Code Formatting..."
if ! terraform fmt -check -recursive "$LAB_PATH"; then
    echo "WARNING: Unformatted files found. Running 'terraform fmt -recursive' to fix..."
    terraform fmt -recursive "$LAB_PATH"
fi

echo "[2/3] Validating Dev Environment..."
(cd "$LAB_PATH/environments/dev" && terraform init -backend=false > /dev/null 2>&1 && terraform validate)

echo "[3/3] Validating Prod Environment..."
(cd "$LAB_PATH/environments/prod" && terraform init -backend=false > /dev/null 2>&1 && terraform validate)

echo "=== All Level 1 Checks Passed Successfully! ==="

echo ""
echo "========================================="
echo " LEVEL 2: GIT STAGING & REVIEW"
echo "========================================="
echo "Branch: $BRANCH"
echo "Commit Message: \"$COMMIT_MSG\""
echo ""
echo "Modified / New Files:"
git status -s

echo ""
echo "-----------------------------------------"
read -p "APPROVAL REQUIRED: Do you approve and want to COMMIT & PUSH to '$BRANCH'? (y/N): " APPROVAL
echo "-----------------------------------------"

if [[ "$APPROVAL" =~ ^[Yy]$ ]]; then
    echo "=== Staging changes ==="
    git add .

    echo "=== Committing changes ==="
    git commit -m "$COMMIT_MSG"

    echo "=== Pushing to remote branch '$BRANCH' ==="
    git push origin "$BRANCH"

    echo ""
    echo "🎉 Successfully committed and pushed to GitHub!"
else
    echo "Git push CANCELLED by user."
    exit 0
fi
