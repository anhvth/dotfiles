# File: zsh/mygroup.sh
# Thisfile contain my-user group function
mygroup_name="anhvth-group"
mygroup_gid="2000"

# Icons for different message types
SUCCESS_ICON="✅"
FAIL_ICON="❌"
WARNING_ICON="⚠️"
INFO_ICON="ℹ️"

mygroup_setup_group(){
    echo "$INFO_ICON This function is to set up user group."
    echo "$INFO_ICON Check if the group exists with the correct name and GID"
    if getent group $mygroup_name > /dev/null; then
        echo "$INFO_ICON Group $mygroup_name already exists."
    else
        echo "$WARNING_ICON Group $mygroup_name does not exist. Creating it now..."
        groupadd -g $mygroup_gid $mygroup_name
        if [ $? -eq 0 ]; then
            echo "$SUCCESS_ICON Group $mygroup_name created successfully."
        else
            echo "$FAIL_ICON Failed to create group $mygroup_name."
            exit 1
        fi
    fi
    echo "$INFO_ICON If not detelete the group, create it with the correct GID"
    if [ $(getent group $mygroup_name | cut -d: -f3) -ne $mygroup_gid ]; then
        echo "$WARNING_ICON Group $mygroup_name exists but with a different GID. Changing it now..."
        groupmod -g $mygroup_gid $mygroup_name
        if [ $? -eq 0 ]; then
            echo "$SUCCESS_ICON Group $mygroup_name GID changed successfully."
        else
            echo "$FAIL_ICON Failed to change GID of group $mygroup_name."
            exit 1
        fi
    fi
    # add the user to the group
    if id -nG "$USER" | grep -qw "$mygroup_name"; then
        echo "$INFO_ICON User $USER is already a member of group $mygroup_name."
    else
        echo "$WARNING_ICON Adding user $USER to group $mygroup_name..."
        usermod -aG $mygroup_name $USER
        if [ $? -eq 0 ]; then
            echo "$SUCCESS_ICON User $USER added to group $mygroup_name successfully."
        else
            echo "$FAIL_ICON Failed to add user $USER to group $mygroup_name."
            exit 1
        fi
    fi
}

mygroup_setup_directory(){
    target_dir=$1
    chown -R :$mygroup_name $target_dir
    echo "$INFO_ICON Changed group ownership of $target_dir to $mygroup_name."
    chmod -R g+rwX $target_dir
    echo "$INFO_ICON Changed permissions of $target_dir to allow group read/write/execute."
}
