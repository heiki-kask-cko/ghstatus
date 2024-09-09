#!/bin/bash

if test "$1" = ""
then
  echo "Usage: ghstatus <org>"
  echo
  echo "Note: you have to perform 'gh auth login' before using the script."
  exit 1
fi

echo "GH org $1 status report"

gh repo list "$1" --limit 500 --no-archived --json nameWithOwner --jq '.[].nameWithOwner' | sort > "$1"-repos.txt
gh search code filename:CODEOWNERS org:"$1" --limit 500 --json repository --jq '.[].repository.nameWithOwner' | sort > "$1"-codeowners.txt

echo "Repositories without CODEOWNERS:"
cat "$1"-repos.txt "$1"-codeowners.txt | sort | uniq -u > "$1"-without-codeowners.txt
cat "$1"-without-codeowners.txt

echo "Scanning CODEOWNERS..."
echo -n > "$1"-invalid-codeowners.txt
while IFS= read -r repo
do
  gh api /repos/"$repo"/codeowners/errors | jq -e '.errors[].message' > /dev/null 2>&1
  if test "$?" != "4"
  then
    echo -n "!"
    echo "$repo" >> "$1"-invalid-codeowners.txt
  else
    echo -n "."
  fi
done < "$1-codeowners.txt"

echo
echo "Repos with invalid or problematic CODEOWNERS:"
cat "$1"-invalid-codeowners.txt

echo "$(cat $1-repos.txt | wc -l ) repositories" > "$1"-stats.txt
echo "$(cat $1-codeowners.txt | wc -l) repositories with CODEOWNERS" >> "$1"-stats.txt
echo "$(cat $1-without-codeowners.txt | wc -l) repositories without CODEOWNERS" >> "$1"-stats.txt
echo "$(cat $1-invalid-codeowners.txt | wc -l) repositories with invalid CODEOWNERS" >> "$1"-stats.txt

echo
echo "Done, "$1" has:"
cat "$1"-stats.txt
