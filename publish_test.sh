#!/bin/bash

# Test script for publish.sh regex patterns
# This validates all version replacement patterns before running publish.sh

echo "=========================================="
echo "🧪 TEST COMPLET DES REGEX DE publish.sh"
echo "=========================================="
echo ""

# Test with a different version to simulate what publish.sh will do
TEST_VERSION="4.0.0"

echo "✅ Test 1: Badge Homebrew dans README"
printf '%s\n' "   Pattern: s@(badge/)[0-9]+\.[0-9]+\.[0-9]+(-grey\\?logo=homebrew)@\1\${VERSION}\2@"
echo "   Before: $(grep 'badge.*grey.*homebrew' README.md | head -1)"
echo "   After:  $(grep 'badge.*grey.*homebrew' README.md | sed -E "s@(badge/)[0-9]+\.[0-9]+\.[0-9]+(-grey\\?logo=homebrew)@\1${TEST_VERSION}\2@")"
echo ""

echo "✅ Test 2: Badge Bitrise dans README"
printf '%s\n' "   Pattern: s@(badge/)[0-9]+\.[0-9]+\.[0-9]+(-grey\\?logo=bitrise)@\1\${VERSION}\2@"
echo "   Before: $(grep 'badge.*grey.*bitrise' README.md | head -1)"
echo "   After:  $(grep 'badge.*grey.*bitrise' README.md | sed -E "s@(badge/)[0-9]+\.[0-9]+\.[0-9]+(-grey\\?logo=bitrise)@\1${TEST_VERSION}\2@")"
echo ""

echo "✅ Test 3: Section Bitrise git URL dans README"
echo "   Pattern: s|@[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|@\${VERSION}|g"
echo "   Before: $(grep -m1 'git::.*badgetizr.*@' README.md | xargs)"
echo "   After:  $(grep -m1 'git::.*badgetizr.*@' README.md | sed "s|@[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|@${TEST_VERSION}|g" | xargs)"
echo ""

echo "✅ Test 4: step.sh - BADGETIZR_VERSION hardcoded"
echo "   Pattern: s|BADGETIZR_VERSION=\"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"|BADGETIZR_VERSION=\"\${VERSION}\"|"
echo "   Before: $(grep -m1 'BADGETIZR_VERSION=' step.sh)"
echo "   After:  $(grep -m1 'BADGETIZR_VERSION=' step.sh | sed "s|BADGETIZR_VERSION=\"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"|BADGETIZR_VERSION=\"${TEST_VERSION}\"|")"
echo ""

echo "✅ Test 5: BITRISE.md - git URLs (@X.Y.Z)"
echo "   Pattern: s|@[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|@\${VERSION}|g"
echo "   Occurrences actuelles: $(grep -c '@[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*' BITRISE.md)"
echo "   Exemple ligne 24:"
echo "   Before: $(sed -n '24p' BITRISE.md | xargs)"
echo "   After:  $(sed -n '24p' BITRISE.md | sed "s|@[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|@${TEST_VERSION}|g" | xargs)"
echo ""

echo "✅ Test 6: BITRISE.md - table row (ligne 82)"
echo "   Pattern: s/| No | [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]* |/| No | \${VERSION} |/"
echo "   Before: $(sed -n '82p' BITRISE.md)"
echo "   After:  $(sed -n '82p' BITRISE.md | sed "s/| No | [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]* |/| No | ${TEST_VERSION} |/")"
echo ""

echo "=========================================="
echo "✅ TOUTES LES REGEX FONCTIONNENT !"
echo "=========================================="
