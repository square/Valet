set -ex

DOCS_ROOT=docs-gen

[ -d $DOCS_ROOT ] && rm -r $DOCS_ROOT
mkdir $DOCS_ROOT

cp -a docs/* $DOCS_ROOT

cp Contributing.md $DOCS_ROOT/contributing.md
cp BUG-BOUNTY.md $DOCS_ROOT/bug-bounty.md
