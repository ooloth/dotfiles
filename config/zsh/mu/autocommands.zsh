# reset CURRENT_DIRECTORY env var after changing directories
function chpwd() { 
  # See: https://stackoverflow.com/questions/1371261/get-current-directory-or-folder-name-without-the-full-path
  export CURRENT_DIRECTORY=${PWD##*/}
}
