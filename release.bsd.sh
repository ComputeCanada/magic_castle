#!/bin/bash
VERSION=$1
shift
CLOUD=($@)

if [ -z "$VERSION" ]; then
    echo "Specify the release version number"
    echo "Usage: release.sh VERSION"
    exit 1
fi

if [ -z "$CLOUD" ]; then
    CLOUD=(aws azure gcp openstack ovh)
fi

TMPDIR=$(mktemp -d)
FOLDER=$TMPDIR/magic_castle-$VERSION

mkdir -p releases
for provider in "${CLOUD[@]}"; do
    cur_folder=$FOLDER/magic_castle-$provider-$VERSION
    mkdir -p $cur_folder
    cp -RfL $provider $cur_folder/
    cp -RfL dns $cur_folder/
    cp -fL examples/$provider/main.tf $cur_folder
    mv $cur_folder/$provider/README.md $cur_folder
    sed -i "" 's;git::https://github.com/ComputeCanada/magic_castle.git//;./;g' $cur_folder/main.tf
    sed -i "" "s;default = \"master\";default = \"$VERSION\";" $cur_folder/$provider/variables.tf
    cp LICENSE $cur_folder

    # Identify and fix provider versions
    # Keeping only the lowest version of a provider if it is present more than once
    TF_PROVIDERS=$(
        find $cur_folder -type d -exec terraform init {} \; |
        grep 'Downloading plugin' |
        sed -E 's/- Downloading plugin for provider "([a-z]*)".*([0-9]{1,}\.[0-9]{1,})\.[0-9]{1,}\.\.\./\2 \1/g' |
        sort -V |
        uniq -f 1 |
        awk '{print $2,$1}' |
        tr " " "_" |
        sort
    )

    echo -e "terraform {\n  required_providers {"  >> $cur_folder/providers.tf
    for prov_vers in $TF_PROVIDERS; do
        prov="${prov_vers%%_*}"
        vers="${prov_vers#*_}"
        file=$(grep -l -R "provider \"$prov\"" $cur_folder)
        file=$(grep -l -R "provider \"$prov\"" $cur_folder)
        if [ ! -z "$file" ]; then
            sed -i ''  '/version = "[<>~]\{1,\} *[0-9.]*"/d' $file
        fi
        echo "    ${prov} = \"~> ${vers}\" " >> $cur_folder/providers.tf
    done
    echo -e "  }\n}"  >> $cur_folder/providers.tf

    cd $FOLDER
    tar czvf magic_castle-$provider-$VERSION.tar.gz magic_castle-$provider-$VERSION
    zip magic_castle-$provider-$VERSION.zip -r magic_castle-$provider-$VERSION
    cd -
    cp $FOLDER/magic_castle-$provider-$VERSION.tar.gz releases/
    cp $FOLDER/magic_castle-$provider-$VERSION.zip releases/
done
rm -rf $TMPDIR
