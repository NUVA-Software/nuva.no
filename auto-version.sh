#!/bin/bash

echo "🚀 Starting auto-version script"

# Get the latest tag from git and use it to get the version number

VERSION=$(git describe --abbrev=0 --tags)
VERSION_NUMBER=$(echo $VERSION | sed 's/v//g')
OLD_VERSION_NUMBER=$(echo $VERSION | sed 's/v//g')
# Get the number of commits since the last tag

COMMITS_SINCE_TAG=$(git rev-list --count $VERSION..HEAD)
MAJOR=$(echo $VERSION_NUMBER | cut -d'.' -f1)

MINOR=$(echo $VERSION_NUMBER | cut -d'.' -f2)
PATCH=$(echo $VERSION_NUMBER | cut -d'.' -f3)
INCREASE_MAJOR=false

INCREASE_MINOR=false
INCREASE_PATCH=false
# Loop through the commits and check the prefix of each commit message

for COMMIT in $(git log --pretty=format:"%H" $VERSION..HEAD); do
    MESSAGE=$(git log --pretty=format:"%s" -n 1 $COMMIT)
    echo "🔍 Checking commit message: \"$MESSAGE\""
    case $MESSAGE in
    breaking:*)
        INCREASE_MAJOR=true
        INCREASE_MINOR=true
        INCREASE_PATCH=true
        echo "   💥 Breaking change detected 💥"
        ;;
    feat:*)
        INCREASE_MINOR=true
        INCREASE_PATCH=true
        echo "   ✨ Minor change detected ✨"
        ;;
    refactor:* | fix:* | build:* | ci:* | docs:* | perf:* | style:* | test:*)
        INCREASE_PATCH=true
        echo "   🛠️ Patch change detected 🛠️"
        ;;
    chore:*)
        echo "   🧹 Chore change detected, does not affect version 🧹"
        ;;
    *)
        echo "   🤷 No change detected, make sure to follow the commit message format! 🤷"
        ;;
    esac
done
if [ "$INCREASE_MAJOR" = true ]; then

    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
elif [ "$INCREASE_MINOR" = true ]; then
    MINOR=$((MINOR + 1))
    PATCH=0
elif [ "$INCREASE_PATCH" = true ]; then
    PATCH=$((PATCH + 1))
fi

GIT_COMMIT_SHA=$(git rev-parse --short HEAD)
VERSION_NUMBER="$((MAJOR)).$((MINOR)).$((PATCH))"
VERSION_NUMBER_FULL="$((MAJOR)).$((MINOR)).$((PATCH))-sha.$GIT_COMMIT_SHA"

echo "$VERSION_NUMBER_FULL" >public/version.txt

git add public/version.txt
git commit -m "chore: set version number to v$VERSION_NUMBER"
git tag -a "v$VERSION_NUMBER" -m "v$VERSION_NUMBER"

echo "Old version: $OLD_VERSION_NUMBER"
echo "New version: $VERSION_NUMBER"
