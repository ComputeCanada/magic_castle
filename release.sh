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
    cp -rfL $provider/*.tf $cur_folder/$provider/
    cp -rfL $provider/*.sh $cur_folder/$provider/
    cp -rfL cloud-init/*.yaml $cur_folder/$provider/cloud-init/
    cp -rfL dns $cur_folder
    cp -fL examples/$provider/main.tf $cur_folder
    sed -i 's;git::https://github.com/ComputeCanada/magic_castle.git//;./;g' $cur_folder/main.tf
    sed -i "s;default = \"master\";default = \"$VERSION\";" $cur_folder/$provider/variables.tf
    cp LICENSE $cur_folder
    cp $provider/README.md $cur_folder

    # Identify and fix provider versions
    TF_PROVIDERS=$(find $cur_folder -type d -exec terraform init {} \; |
                grep '* provider' |
                sed -E 's/\* provider\.([a-z]*): version = "~> ([0-9.]*)"/\1_\2/g' |
                sort |
                uniq)
    for prov_vers in $TF_PROVIDERS; do
        prov="${prov_vers%%_*}"
        vers="${prov_vers#*_}"
        file=$(grep -l -R "provider \"$prov\"" $cur_folder)
        if [ ! -z "$file" ]; then
            sed -i "/provider \"$prov\"/a \ \ version = \"~> ${vers}\"" $file
        else
            echo "provider \"${prov}\" { version = \"~> ${vers}\" } " >> $cur_folder/$provider/providers.tf
        fi
    done

    cd $FOLDER
    tar czvf magic_castle-$provider-$VERSION.tar.gz magic_castle-$provider-$VERSION
    zip magic_castle-$provider-$VERSION.zip -r magic_castle-$provider-$VERSION
    cd -
    cp $FOLDER/magic_castle-$provider-$VERSION.tar.gz releases/
    cp $FOLDER/magic_castle-$provider-$VERSION.zip releases/
done
rm -rf $TMPDIR