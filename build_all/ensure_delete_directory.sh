# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.



if [[ -z $1 ]]; then
    echo "ensure_delete_directory.sh needs as input a path to the directory to delete"
    exit 1
else
    if [[ -d $1 ]]; then
        rm -Rf $1
    else 
        echo "$1 is not a directory"
        exit 1
    fi
fi 
rm -r $1 2>&1 > /dev/null
if [[ $? -neq 0]]; then
    echo Failed to delete directory: $1
    exit 1
fi

echo Deleted directory: $1
exit 0
