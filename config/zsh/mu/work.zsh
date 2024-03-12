if $IS_WORK_LAPTOP; then

  alias bp='cd $HOME/Repos/recursionpharma/build-pipelines'
  alias eo='cd $HOME/Repos/recursionpharma/eng-onboarding'
  # see: https://stackoverflow.com/a/51563857/8802485
  alias gca='gcloud auth login'
  alias gci='gcloud init'
  alias gcpi='gcloud config set project eng-infrastructure'
  alias gcpn='gcloud config set project rp006-prod-49a893d8'
  alias genie='cd $HOME/Repos/recursionpharma/genie'
  alias gu='cd $HOME/Repos/recursionpharma/genie/genie-ui'
  alias mp='cd $HOME/Repos/recursionpharma/mapapp-public'

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

  alias pa='cd $HOME/Repos/recursionpharma/dash-phenoapp-v2'
  alias pab='cd $HOME/Repos/recursionpharma/dash-phenoapp-v2/phenoapp'
  alias paf='cd $HOME/Repos/recursionpharma/dash-phenoapp-v2/react-app'
  alias pm='cd $HOME/Repos/recursionpharma/phenomap'
  alias pr='cd $HOME/Repos/recursionpharma/phenoreader'
  alias psa='cd $HOME/Repos/recursionpharma/phenoservice-api'
  alias psc='cd $HOME/Repos/recursionpharma/phenoservice-consumer'
  alias pu='cd $HOME/Repos/recursionpharma/platelet-ui'
  alias pw='cd $HOME/Repos/recursionpharma/processing-witch'
  alias r='cd $HOME/Repos/recursionpharma'

  rl() { roadie lock -- $1; } # optionally "rl -c" etc
  rlc() { roadie lock -c; }
  ru() { pip install -U roadie; } # see: https://pip.pypa.io/en/stable/cli/pip_install/#options

  run() {
    local CURRENT_DIRECTORY=$(basename $PWD)

    case $CURRENT_DIRECTORY in
      # TODO: automatically rerun rv if any pip packages were updated
      dash-phenoapp-v2) pip install jupyter && python phenoapp/app.py ;;
      # silence out of control watchdog output when working locally
      # dash-phenoapp-v2) pip uninstall watchdog -y && python phenoapp/app.py ;;
      # the genie docker compose file starts the frontend, backend and db (no need to run any separately)
      genie)            du ;;
      grey-havens)      ./run-local.sh ;;
      # TODO: javascript-template-react)
      phenoapp)         pa && pip install jupyter && python phenoapp/app.py ;;
      # phenoapp)         pa && pip uninstall watchdog -y && python phenoapp/app.py ;;
      # TODO: platelet)
      # FIXME: do I really need "n" first?
      platelet-ui)      n && du ;;
      react-app)        ns ;;
      tech)             ns ;;
      *)                echo "🚨 No 'run' case defined for '/${CURRENT_DIRECTORY}' in work.zsh" ;;
    esac
  }

  rv() {
    local CURRENT_DIRECTORY=$(basename $PWD)

    # Install latest version of roadie, then rebuild venv to remove any no-longer-used packages
    # https://github.com/recursionpharma/roadie/blob/5a5c6ba44c345c8fd42543db5454b502a4e96863/roadie/cli/virtual.py#L454
    ru && roadie venv --clobber

    # silence out of control watchdog output when working locally
    if [[ "$CURRENT_DIRECTORY" == "dash-phenoapp-v2" ]]; then
      # see: https://pip.pypa.io/en/stable/cli/pip_uninstall/
      pip uninstall watchdog -y
    fi
  }

  alias tech='cd $HOME/Repos/recursionpharma/tech'

  # TODO: test() {}
  # TODO: format() {}
  # TODO: lint() {}
  # TODO: typecheck() {}

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
  export C_INCLUDE_PATH=/opt/homebrew/Cellar/librdkafka/2.3.0/include
  export LIBRARY_PATH=/opt/homebrew/Cellar/librdkafka/2.3.0/lib

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

  # sbin
  export PATH="/opt/homebrew/sbin:$PATH"

  # vault (griphook)
  # see: https://github.com/recursionpharma/data-science-onboarding#setting-up-griphook
  source $HOME/.griphook/env
fi

