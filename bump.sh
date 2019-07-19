#!/bin/bash

# Thanks goes to @pete-otaqui for the initial gist:
# https://gist.github.com/pete-otaqui/4188238
#
# Original version modified by Marek Suscak
#
# works with a file called VERSION in the current directory,
# the contents of which should be a semantic version number
# such as "1.2.3" or even "1.2.3-beta+001.ab"

# this script will display the current version, automatically
# suggest a "minor" version update, and ask for input to use
# the suggestion, or a newly entered value.

# New revision modified by Nomane Oulali
# - Add some reliability stuff like controlling that last commit is
#   not already tagged
# - Allow custom comment when you apply your tags
# - Increment patch field instead of minor
# Thanks to Marek Suscak for the original version
# https://gist.github.com/mareksuscak/1f206fbc3bb9d97dec9c

# once the new version number is determined, the script will
# pull a list of changes from git history, prepend this to
# a file called CHANGELOG.md (under the title of the new version
# number), give user a chance to review and update the changelist
# manually if needed and create a GIT tag.

NOW="$(date +'%B %d, %Y')"
RED="\033[1;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

LATEST_HASH=`git log --pretty=format:'%h' -n 1`
PREFIX_VERSION=`git config gitflow.prefix.versiontag`
REPO_ORIGIN=`git config --get remote.origin.url`
REPO_NAME=`basename -s .git $REPO_ORIGIN`

DATE=`date +%Y-%m-%d`

QUESTION_FLAG="${GREEN}?"
WARNING_FLAG="${YELLOW}!"
NOTICE_FLAG="${CYAN}❯"

# $1 : last version
# $2 : new version
function changelog {
    echo "## [$2 - ($DATE)](https://github.com/InterConnecta/$REPO_NAME/compare/$PREFIX_VERSION$1...$PREFIX_VERSION$2)"  > tmpfile
    echo "" >> tmpfile
    if [ "$LAST_VERSION" = "0.0.0" ]
    then
        git log --pretty=format:"  - %s ([%h](https://github.com/InterConnecta/$REPO_NAME/commit/%h))" --no-merges  >> tmpfile
    else
        git log $PREFIX_VERSION$1..HEAD --pretty=format:"  - %s ([%h](https://github.com/InterConnecta/$REPO_NAME/commit/%h))" --no-merges  >> tmpfile
    fi
    echo "" >> tmpfile
    echo "" >> tmpfile
    echo "### Added" >> tmpfile
    echo "### Changed" >> tmpfile
    echo "### Deprecated" >> tmpfile
    echo "### Removed" >> tmpfile
    echo "### Fixed" >> tmpfile
    echo "### Security" >> tmpfile
    echo "" >> tmpfile
    echo "" >> tmpfile
    cat CHANGELOG.md >> tmpfile
    mv tmpfile CHANGELOG.md
}

# GET LAST RELEASE VERSION
echo -ne "${QUESTION_FLAG} ${CYAN}Please enter the last release version: "
read LAST_VERSION
if [ "$LAST_VERSION" = "" ]
then
    LAST_VERSION="0.0.0"
fi

#GET TYPE OF RELEASE
echo -e "${QUESTION_FLAG} ${CYAN}Please select the release type: "
options=("Feature" "Hotfix")
select TYPE in "${options[@]}";
do
     break
done

#SUGGESTED VERSION
BASE_LIST=(`echo $LAST_VERSION | tr '.' ' '`)
V_MAJOR=${BASE_LIST[0]}
V_MINOR=${BASE_LIST[1]}
V_PATCH=${BASE_LIST[2]}
if [ "$TYPE" = "Feature" ]; then
    V_MINOR=$((V_MINOR + 1))
    V_PATCH=0
fi
if [ "$TYPE" = "Hotfix" ]; then
    V_PATCH=$((V_PATCH + 1))
fi
SUGGESTED_VERSION="$V_MAJOR.$V_MINOR.$V_PATCH"

# GET NEW VERSION TO RELEASE
echo -ne "${QUESTION_FLAG} ${CYAN}Please enter the new version to release [${WHITE}$SUGGESTED_VERSION${CYAN}]: "
read NEW_VERSION
if [ "$NEW_VERSION" = "" ]; then NEW_VERSION=$SUGGESTED_VERSION; fi

#CHANGELOG
changelog "${LAST_VERSION}" "${NEW_VERSION}"
echo -e "${GREEN}Your CHANGELOG.md has been update/created. You can edit it in accordance with the best practices."
echo -e "${GREEN}https://keepachangelog.com/en/1.0.0/"
