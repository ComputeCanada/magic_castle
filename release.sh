#!/bin/bash
VERSION=$1

if [ -z "$VERSION" ]
then
    echo "Specify the release version number"
    echo "Usage: release.sh VERSION"
    exit 1
fi

TMPDIR=$(mktemp -d)
FOLDER=$TMPDIR/magic_castle-$VERSION
CLOUD=(aws azure gcp openstack ovh)

mkdir -p releases
for provider in "${CLOUD[@]}"; do
    cur_folder=$FOLDER/magic_castle-$provider-$VERSION
    mkdir -p $cur_folder
    mkdir -p $cur_folder/$provider/cloud-init/
    cp -rf $provider/*.tf $cur_folder/$provider/
    cp -rf $provider/*.sh $cur_folder/$provider/
    cp -rf cloud-init/*.yaml $cur_folder/$provider/cloud-init/
    cp -rf dns $cur_folder
    cp examples/$provider/main.tf $cur_folder
    sed -i '' 's;git::https://github.com/ComputeCanada/magic_castle.git//;./;g' $cur_folder/main.tf
    sed -i '' "s;default = \"master\";default = \"$VERSION\";" $cur_folder/$provider/variables.tf
    cp LICENSE $cur_folder
    cp $provider/README.md $cur_folder
    cd $FOLDER
    tar czvf magic_castle-$provider-$VERSION.tar.gz magic_castle-$provider-$VERSION 
    zip magic_castle-$provider-$VERSION.zip -r magic_castle-$provider-$VERSION
    cd -
    cp $FOLDER/magic_castle-$provider-$VERSION.tar.gz releases/
    cp $FOLDER/magic_castle-$provider-$VERSION.zip releases/
done
