#!/bin/bash
set -e
VERSION=$1
shift
CLOUD=($@)

if [ -z "$VERSION" ]; then
    echo "Specify the release version number"
    echo "Usage: release.sh VERSION"
    exit 1
fi

if [ -z "$CLOUD" ]; then
    CLOUD=(aws azure gcp openstack ovh incus)
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
    cp -RfL common $cur_folder/
    rm $cur_folder/common/{variables,outputs}.tf
    cp -RfL dns $cur_folder/
    cp -RfL $provider $cur_folder/
    cp -fL examples/$provider/main.tf $cur_folder
    mv $cur_folder/$provider/README.md $cur_folder
    sed_i 's;git::https://github.com/ComputeCanada/magic_castle.git//;./;g' $cur_folder/main.tf
    sed_i "s;\"main\";\"$VERSION\";" $cur_folder/main.tf
    cp LICENSE $cur_folder

    ## Initialize to create .terraform.lock.hcl file
    cd $cur_folder
    ## Make sure only one module is named "dns"
    sed_i '1,/dns/s/dns/cloudflare/' main.tf
    ## Uncomment DNS modules
    sed_i 's/^#\ //g' main.tf
    # TODO: skip plugins download once Terraform issue #25813 is fixed
    terraform init
    rm -rf .terraform
    cd -

    ## Recreate a new unmodified main.tf
    cp -fL examples/$provider/main.tf $cur_folder
    sed_i 's;git::https://github.com/ComputeCanada/magic_castle.git//;./;g' $cur_folder/main.tf
    sed_i "s;\"main\";\"$VERSION\";" $cur_folder/main.tf

    cd $FOLDER
    tar czvf magic_castle-$provider-$VERSION.tar.gz magic_castle-$provider-$VERSION
    zip magic_castle-$provider-$VERSION.zip -r magic_castle-$provider-$VERSION
    cd -
    cp $FOLDER/magic_castle-$provider-$VERSION.tar.gz releases/
    cp $FOLDER/magic_castle-$provider-$VERSION.zip releases/
done
rm -rf $TMPDIR
