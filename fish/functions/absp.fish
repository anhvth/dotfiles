#!/usr/bin/env fish

function absp
    set file_or_folder "$argv[1]"
    set current_dir (pwd)

    # If no argument is provided, use fzf to select a file/folder
    if test -z "$file_or_folder"
        set file_or_folder (fzf)
    end

    # Remove leading ./ or / if present
    set file_or_folder (string replace -r '^\./' '' "$file_or_folder")
    set file_or_folder (string replace -r '^/' '' "$file_or_folder")

    # If the file_or_folder is not an absolute path, prepend the current directory
    if not string match -q '/*' "$file_or_folder"
        set file_or_folder "$current_dir/$file_or_folder"
    end

    # Remove any double slashes
    set file_or_folder (string replace -a '//' '/' "$file_or_folder")

    echo "$cname:$file_or_folder"
end