if $IS_WORK_LAPTOP; then

  bp() { cd $HOME/Repos/recursionpharma/build-pipelines; }
  cauldron() { cd $HOME/Repos/recursionpharma/cauldron; }
  eo() { cd $HOME/Repos/recursionpharma/eng-onboarding; }
  # see: https://stackoverflow.com/a/51563857/8802485
  # see: https://cloud.google.com/docs/authentication/gcloud#gcloud-credentials
  gca() { gcloud auth login; }
  gcaa() { gcloud auth application-default login; }
  gci() { gcloud init; }
  gcpe() { gcloud config set project eng-infrastructure; }
  gcpn() { gcloud config set project rp006-prod-49a893d8; }
  genie() { cd $HOME/Repos/recursionpharma/genie }
  gu() { cd $HOME/Repos/recursionpharma/genie/genie-ui; }
  mp() { cd $HOME/Repos/recursionpharma/mapapp-public; }
  n() { npm install "$@"; }
  nb() { n && npm run build; }
  nfc() { npm run format:check; }
  nff() { npm run format:fix; }
  nk() { npm run typecheck; }
  nl() { npm run lint; }
  nlc() { npm run lint:check; }
  nlf() { npm run lint:fix; }
  ns() { n && npm run start; }
  nt() { npm run test "$@"; }
  nu() { n && npm-check -u; }
  pa() { cd $HOME/Repos/recursionpharma/dash-phenoapp-v2; }
  pab() { cd $HOME/Repos/recursionpharma/dash-phenoapp-v2/phenoapp; }
  paf() { cd $HOME/Repos/recursionpharma/dash-phenoapp-v2/react-app; }
  pm() { cd $HOME/Repos/recursionpharma/phenomap; }
  pr() { cd $HOME/Repos/recursionpharma/phenoreader; }
  psa() { cd $HOME/Repos/recursionpharma/phenoservice-api; }
  psc() { cd $HOME/Repos/recursionpharma/phenoservice-consumer; }
  pl() { cd $HOME/Repos/recursionpharma/platelet; }
  plu() { cd $HOME/Repos/recursionpharma/platelet-ui; }
  pw() { cd $HOME/Repos/recursionpharma/processing-witch; }
  r() { cd $HOME/Repos/recursionpharma; }
  rl() { roadie lock "$@"; } # optionally "rl -c" etc
  rlc() { rl -c; }
  ru() { python -m pip install -U roadie; } # see: https://pip.pypa.io/en/stable/cli/pip_install/#options
  rv() {
    # Install latest version of roadie, then rebuild venv to remove any no-longer-used packages
    # https://github.com/recursionpharma/roadie/blob/5a5c6ba44c345c8fd42543db5454b502a4e96863/roadie/cli/virtual.py#L454
    ru && roadie venv --clobber
  }
  skurge() { cd $HOME/Repos/recursionpharma/skurge; }

  start() {
    local CURRENT_DIRECTORY=$(basename $PWD)

    case $CURRENT_DIRECTORY in
      cauldron)
        du ;;

      dash-phenoapp-v2)
        # TODO: automatically rerun rv if any pip packages were updated?
        printf "\n🏁 Starting observability stack...\n\n"
        du
        printf "\n🏁 Starting flask app...\n\n"
        CONFIGOME_ENV=dev \
        FLASK_APP=phenoapp.app.py \
        FLASK_DEBUG=true \
        FLASK_ENV=development \
        FLASK_RUN_PORT=8050 \
        GOOGLE_CLOUD_PROJECT=eng-infrastructure \
        PROMETHEUS_MULTIPROC_DIR=./.prom \
        flask run ;;

      genie)
        # the genie docker compose file starts the frontend, backend and db (no need to run any separately)
        du ;;

      grey-havens)
        ./run-local.sh ;;

      # TODO: javascript-template-react)

      phenoapp)
        pa && python phenoapp/app.py ;;

      platelet)
        # see: https://github.com/recursionpharma/platelet/blob/trunk/docs/setup/index.md
        printf "🏁 Starting platelet...\n"
        gcpe
        du ;;

      platelet-ui)
        printf "🏁 Starting cauldron, genie, skurge, platelet and platelet-ui...\n"
        cauldron && dud
        genie && dud
        pl && dud
        skurge && dud
        plu && n && du ;;

      processing-witch)
        # TODO: start anything else locally? leverage docker compose?
        python -m main ;;

      react-app)
        ns ;;

      skurge)
        du ;;

      tech)
        ns ;;

      *)
        printf "🚨 No 'start' case defined for '/${CURRENT_DIRECTORY}' in work.zsh" ;;
    esac
  }

  stop() {
    local CURRENT_DIRECTORY=$(basename $PWD)

    case $CURRENT_DIRECTORY in
      cauldron)
        dd ;;

      dash-phenoapp-v2)
        dd ;;

      genie)
        dd ;;

      phenoapp)
        dd ;;

      platelet-ui)
        printf "✋ Stopping cauldron, genie, skurge, platelet and platelet-ui...\n"
        cauldron && dd
        genie && dd
        pl && dd
        skurge && dd
        plu && dd ;;

      skurge)
        dd ;;

      *)
        echo "🚨 No 'stop' case defined for '/${CURRENT_DIRECTORY}' in work.zsh" ;;
    esac
  }

  tech() { cd $HOME/Repos/recursionpharma/tech; }
  zuul() { cd $HOME/Repos/recursionpharma/zuul; }

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

  # see: https://stackoverflow.com/a/47867652/8802485
  # see: https://cloud.google.com/docs/authentication/application-default-credentials
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"

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

  # sbin
  export PATH="/opt/homebrew/sbin:$PATH"

  # vault (griphook)
  # see: https://github.com/recursionpharma/data-science-onboarding#setting-up-griphook
  source $HOME/.griphook/env
fi
