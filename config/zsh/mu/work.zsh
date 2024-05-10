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
  lowe() { cd $HOME/Repos/recursionpharma/bc-lowe; }
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

    local CURRENT_DIRECTORY=$(basename $PWD)

    if [[ "$CURRENT_DIRECTORY" == "dash-phenoapp-v2" ]]; then
      # Install debugpy to support debugging the flask app by attaching to it
      pip install debugpy
    fi
  }

  skurge() { cd $HOME/Repos/recursionpharma/skurge; }

  start() {
    local CURRENT_DIRECTORY=$(basename $PWD)

    case $CURRENT_DIRECTORY in
      # NOTE: these only apply if not able to use the dev container; if I am, use it and do this instead:
      # https://github.com/recursionpharma/bc-lowe/blob/trunk/README.md#quickstart
      bc-lowe)
        # See: https://recursion.slack.com/archives/D03LJSVPQ67/p1715265297434329?thread_ts=1715264518.353969&cid=D03LJSVPQ67

        # Ensure Docker Desktop is running and Kubernetes is enabled
        info "📡 Pointing to Docker Desktop's Kubernetes instance"
        kubectl config use-context docker-desktop

        info "🚀 Starting postgres on port 5432"
        brew services stop postgresql@14
        lsof -t -i:5432 | xargs kill -9
        kubectl apply -f deploy/local/postgres.yaml
        kubectl wait --for=condition=ready pod -l app=postgres
        kubectl port-forward svc/postgres 5432:5432 & \

        info "🚀 Starting redis on port 6379"
        brew services stop redis
        lsof -t -i:6379 | xargs kill -9
        kubectl apply -f deploy/local/redis.yaml
        kubectl wait --for=condition=ready pod -l app=redis
        kubectl port-forward svc/redis 6379:6379 & \

        info "🚀 Starting backend server with bazel"
        pip_index_url=$(python3 -m pip config get global.index-url)
        PIP_INDEX_URL=$pip_index_url bazel run //src/api:manage migrate
        PIP_INDEX_URL=$pip_index_url bazel run //src/api:manage runserver

        info "🚀 Starting worker with bazel"
        PIP_INDEX_URL=$pip_index_url bazel run //src/api:worker

        # Ensure necessary NEXT_PUBLIC_* environment variables are set in .env.local
        info "🚀 Starting frontend server with pnpm"
        fnm use 20
        pnpm i
        pnpm run web:dev ;;

      cauldron)
        du ;;

      dash-phenoapp-v2)
        # TODO: automatically rerun rv if any pip packages were updated?
        info "🚀 Starting observability stack"
        du
        info "🚀 Starting backend server with debugpy listening"
        FLASK_APP=phenoapp.app.py \
        FLASK_DEBUG=true \
        FLASK_ENV=development \
        FLASK_RUN_PORT=8050 \
        GOOGLE_CLOUD_PROJECT=eng-infrastructure \
        PROMETHEUS_MULTIPROC_DIR=./.prom \
        PYDEVD_DISABLE_FILE_VALIDATION=true \
        python -m debugpy --listen 5678 -m flask run --no-reload ;;

      genie)
        # the genie docker compose file starts the frontend, backend and db (no need to run any separately)
        du ;;

      grey-havens)
        ./run-local.sh ;;

      # TODO: javascript-template-react)

      platelet)
        # see: https://github.com/recursionpharma/platelet/blob/trunk/docs/setup/index.md
        GOOGLE_CLOUD_PROJECT=eng-infrastructure du ;;

      platelet-ui)
        info "🚀 Starting cauldron, genie, skurge, platelet and platelet-ui"
        cauldron && dud
        genie && dud
        pl && dud
        skurge && dud
        plu && n && du ;;

      processing-witch)
        # TODO: start anything else locally? leverage docker compose?
        python -m main ;;

      react-app)
        info "🚀 Starting frontend server"
        ns ;;

      skurge)
        du ;;

      tech)
        ns ;;

      *)
        error "🚨 No 'start' case defined for '/${CURRENT_DIRECTORY}' in work.zsh" ;;
    esac
  }

  stop() {
    local CURRENT_DIRECTORY=$(basename $PWD)

    case $CURRENT_DIRECTORY in
      bc-lowe)
        info "✋ Stopping postgres instance running on port 5432"
        kubectl delete -f deploy/local/postgres.yaml
        lsof -t -i:5432 | xargs kill -9

        info "✋ Stopping redis instance running on port 6379"
        kubectl delete -f deploy/local/redis.yaml
        lsof -t -i:6379 | xargs kill -9 ;;

      cauldron)
        info "✋ Stopping cauldron"
        dd ;;

      dash-phenoapp-v2)
        info "✋ Stopping observability stack"
        dd ;;

      genie)
        info "✋ Stopping genie"
        dd ;;

      platelet-ui)
        info "✋ Stopping cauldron, genie, skurge, platelet and platelet-ui"
        cauldron && dd
        genie && dd
        pl && dd
        skurge && dd
        plu && dd ;;

      skurge)
        dd ;;

      *)
        error "🚨 No 'stop' case defined for '/${CURRENT_DIRECTORY}' in work.zsh\n" ;;
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
