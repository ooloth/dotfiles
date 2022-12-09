# list directory contents after changing directories
function chpwd() { 
  # See: https://stackoverflow.com/questions/1371261/get-current-directory-or-folder-name-without-the-full-path
  export CURRENT_DIRECTORY=${PWD##*/}

  exa --all --group-directories-first 
} 

