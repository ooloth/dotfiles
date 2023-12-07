if $IS_WORK_LAPTOP; then

  bp() { cd $HOME/Repos/recursionpharma/build-pipelines; }
  eo() { cd $HOME/Repos/recursionpharma/eng-onboarding; }
  ip() { cd $HOME/Repos/recursionpharma/ipg-processing; }
  is() { cd $HOME/Repos/recursionpharma/iw-system; }
  iu() { cd $HOME/Repos/recursionpharma/grey-havens; } # soon to be renamed "iw-ui"
  mp() { cd $HOME/Repos/recursionpharma/mapapp-public; }
  n() { npm install -- $1; }
  nb() { n && npm run build; }
  nfc() { npm run format:check; }
  nff() { npm run format:fix; }
  nk() { npm run typecheck; }
  nl() { npm run lint; }
  nlc() { npm run lint:check; }
  nlf() { npm run lint:fix; }
  ns() { n && npm run start; }
  nt() { npm run test -- $1; }
  nu() { n && npm-check -u; }
  pa() { cd $HOME/Repos/recursionpharma/dash-phenoapp-v2; }
  pab() { cd $HOME/Repos/recursionpharma/dash-phenoapp-v2/phenoapp; }
  paf() { cd $HOME/Repos/recursionpharma/dash-phenoapp-v2/react-app; }
  pm() { cd $HOME/Repos/recursionpharma/phenomap; }
  pr() { cd $HOME/Repos/recursionpharma/phenoreader; }
  psa() { cd $HOME/Repos/recursionpharma/phenoservice-api; }
  psc() { cd $HOME/Repos/recursionpharma/phenoservice-consumer; }
  r() { cd $HOME/Repos/recursionpharma; }
  rl() { roadie lock -- $1; } # optionally "rl -c" etc
  rlc() { roadie lock -c; }
  ru() { pip install -U 'roadie[cli]'; } # see: https://pip.pypa.io/en/stable/cli/pip_install/#options
  rv() {
    local CURRENT_DIRECTORY=$(basename $PWD)

    ru && roadie venv

    # silence out of control watchdog output when working locally
    if [[ "$CURRENT_DIRECTORY" == "dash-phenoapp-v2" ]]; then
      # see: https://pip.pypa.io/en/stable/cli/pip_uninstall/
      pip uninstall watchdog -y
    fi
  }

  activate_venv() {
    local CURRENT_DIRECTORY=$(basename $PWD)

    # "roadie venv" always creates a venv named after the current directory
    local PYENV_VENV="${PYENV_ROOT}/versions/${CURRENT_DIRECTORY}"

    # if there's no pyenv venv for this directory, deactivate any venv sticking from a previous directory and be done
    if [[ ! -d "$PYENV_VENV" ]]; then
      export VIRTUAL_ENV=''
      return
    fi

    # its much faster to activate the venv directly and not use the pyenv shell integration at all ("pyenv init" + "pyenv shell <venv>")
    # see: https://stackoverflow.com/a/74290100/8802485
    # see: https://stackoverflow.com/questions/45554864/why-am-i-getting-permission-denied-when-activating-a-venv
    source "${PYENV_VENV}/bin/activate"
  }

  # automatically activate appropriate venv when zsh first loads (called again in autocommands.zsh whenever cwd changes)
  activate_venv

  run() {
    local CURRENT_DIRECTORY=$(basename $PWD)

    case $CURRENT_DIRECTORY in
      # silence out of control watchdog output when working locally
      dash-phenoapp-v2) python phenoapp/app.py ;;
      # dash-phenoapp-v2) pip uninstall watchdog -y && python phenoapp/app.py ;;
      phenoapp)         pa && python phenoapp/app.py ;;
      # phenoapp)         pa && pip uninstall watchdog -y && python phenoapp/app.py ;;
      react-app)        ns ;;
      *)                echo "🚨 No 'run' case defined for '/${CURRENT_DIRECTORY}' in work.zsh" ;;
    esac
  }

  # gcloud
  # see: https://cloud.google.com/sdk/docs/downloads-interactive
  # The next line updates PATH for the Google Cloud SDK.
  if [ -f '/Users/michael.uloth/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/michael.uloth/google-cloud-sdk/path.zsh.inc'; fi

  # The next line enables shell command completion for gcloud.
  if [ -f '/Users/michael.uloth/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/michael.uloth/google-cloud-sdk/completion.zsh.inc'; fi

  # grey-havens
  export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
  export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1

  # IPG
  # see: https://app.swimm.io/workspaces/ctl2gE0Uy2okwcN3LfOg/repos/Z2l0aHViJTNBJTNBaXBnLW9yY2hlc3RyYXRvciUzQSUzQXJlY3Vyc2lvbnBoYXJtYQ==/branch/trunk/docs/v0jze
  export CONFIGOME_ENV=dev

  # kafka
  # TODO: update versions whenever I run brew update
  export C_INCLUDE_PATH=/opt/homebrew/Cellar/librdkafka/2.1.1/include
  export LIBRARY_PATH=/opt/homebrew/Cellar/librdkafka/2.1.1/lib

  # netskope
  # see: https://github.com/recursionpharma/netskope_dev_tools
  source "$HOME/.config/netskope/env.sh"

  # openSSL
  export PATH=/opt/homebrew/opt/openssl@3/bin:$PATH
  export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"

  # prometheus (dash-phenoapp-v2 backend server)
  export PROMETHEUS_MULTIPROC_DIR=./.prom

  # pyenv
  # NOTE: do NOT use eval "$(pyenv init -)" or eval "$(pyenv virtualenv-init -)" (they slow the shell down a lot)

  # python
  # see: https://github.com/recursionpharma/data-science-onboarding#cloning-some-internal-repos
  export PYTHONPATH="$PYTHONPATH:/Users/$USER"
  export MYPYPATH=.

  # sbin
  export PATH="/opt/homebrew/sbin:$PATH"

  # vault (griphook)
  # see: https://github.com/recursionpharma/data-science-onboarding#setting-up-griphook
  source $HOME/.griphook/env
fi

