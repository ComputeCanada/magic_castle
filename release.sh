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

if [ "$(uname)" == "Linux" ]; then
    sed_i () {
        sed -i "$@"
    }
elif [ "$(uname)" == "Darwin" ]; then
    sed_i () {
        sed -i "" "$@"
    }
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
    sed_i 's;git::https://github.com/ComputeCanada/magic_castle.git//;./;g' $cur_folder/main.tf
    sed_i "s;\"master\";\"$VERSION\";" $cur_folder/$provider/variables.tf
    cp LICENSE $cur_folder

    # Identify and fix provider versions
    # Keeping only the lowest version of a provider if it is present more than once
    cd $cur_folder
    export TF_PROVIDERS=$(
        find $cur_folder -type d -exec terraform init {}  \; |
        grep '\- Installed [a-z/-]* v[0-9.]*' |
        sed -E 's/- Installed ([a-z/-]*) v([0-9\.]*).*/\1 \2/g' |
        sort -V |
        uniq -f 0 |
        tr " " "_" |
        sort
    )
    rm -rf .terraform
    cd -
    echo -e "terraform {\n  required_providers {"  >> $cur_folder/providers.tf
    for prov_vers in $TF_PROVIDERS; do
        source="${prov_vers%%_*}"
        vers="${prov_vers#*_}"
        prov="${source#*/}"
        file=$(grep -l -R "provider \"${prov}\"" $cur_folder)
        if [ ! -z "$file" ]; then
            sed_i '/version = "[<>~]\{1,\} *[0-9.]*"/d' $file
        fi
        echo "
    ${prov} = {
        source = \"${source}\"
        version = \"~> ${vers}\"
    }" >> $cur_folder/providers.tf
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