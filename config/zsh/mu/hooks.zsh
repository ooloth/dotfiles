function chpwd() { 
  # reset CURRENT_DIRECTORY env var after changing directories
  # See: https://stackoverflow.com/questions/1371261/get-current-directory-or-folder-name-without-the-full-path
  export CURRENT_DIRECTORY=${PWD##*/}

  # automatically activate appropriate venv when cwd changes
  activate_venv
}
