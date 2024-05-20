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
      info "🚀 Starting flask server with debugpy"
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
      python -m main ;;

    react-app)
      info "🚀 Starting vite server"
      ns ;;

    skurge)
      du ;;

    tech)
      ns ;;

    *)
      error "🚨 No 'start' case defined for '/${CURRENT_DIRECTORY}'" ;;
  esac
}