if $IS_WORK_LAPTOP; then

  function eo() { cd $HOME/Repos/recursionpharma/eng-onboarding && venv }
  function n() { npm install }
  function nb() { n && npm run build }
  function nfc() { npm run format:check }
  function nff() { npm run format:fix }
  function nk() { npm run typecheck }
  function nl() { npm run lint }
  function ns() { n && npm run start }
  function nt() { npm run test }
  function ntp() { nt -- --testPathPattern=$1 }
  function pa() { cd $HOME/Repos/recursionpharma/dash-phenoapp-v2 && venv }
  function pab() { cd $HOME/Repos/recursionpharma/dash-phenoapp-v2/phenoapp && venv }
  function paf() { cd $HOME/Repos/recursionpharma/dash-phenoapp-v2/react-app }
  function pm() { cd $HOME/Repos/recursionpharma/phenomap && venv }
  function pr() { cd $HOME/Repos/recursionpharma/phenoreader && venv }
  function psa() { cd $HOME/Repos/recursionpharma/phenoservice-api && venv }
  function psc() { cd $HOME/Repos/recursionpharma/phenoservice-consumer && venv }
  function r() { cd $HOME/Repos/recursionpharma } 
  function rv() { pip install -U 'roadie[cli]' && roadie venv }

  function venv() {
    eval "$(pyenv init -)" 
    case $CURRENT_DIRECTORY in
      dash-phenoapp-v2 | phenoapp) pyenv shell dash-phenoapp-v2 ;;
      eng-onboarding)              pyenv shell eng-onboarding ;; 
      phenoreader)                 pyenv shell phenoreader ;;
      phenoservice-api)            pyenv shell phenoservice-api ;;
      phenoservice-consumer)       pyenv shell phenoservice-consumer ;;
      *)                           echo "🚨 No 'venv' condition set for '/${CURRENT_DIRECTORY}' in work.zsh" ;;
      # *)                           source venv/bin/activate ;;
    esac
  }

  function edit() {
    case $CURRENT_DIRECTORY in
      dash-phenoapp-v2 | phenoapp | react-app) pa && nvim ;;
      dotfiles)                                dot && nvim ;; 
      eng-onboarding)                          eo && nvim ;; 
      phenomap)                                pm && nvim ;; 
      phenoreader)                             pr && nvim ;; 
      phenoservice-api)                        psa && nvim ;; 
      phenoservice-consumer)                   psc && nvim ;; 
      *)                                       echo "🚨 No 'edit' condition set for '/${CURRENT_DIRECTORY}' in work.zsh" ;;
    esac
  }

  function run() {
    case $CURRENT_DIRECTORY in
      dash-phenoapp-v2 | phenoapp) pa && python phenoapp/app.py ;;
      react-app)                   ns ;;
      *)                           echo "🚨 No 'run' condition set for '/${CURRENT_DIRECTORY}' in work.zsh" ;;
    esac
  }

  # Confluent-Kafka
  # TODO: update these whenever I run brew update
  export C_INCLUDE_PATH=/opt/homebrew/Cellar/librdkafka/1.9.2/include
  export LIBRARY_PATH=/opt/homebrew/Cellar/librdkafka/1.9.2/lib

  # OpenSSL
  export PATH=/opt/homebrew/opt/openssl@3/bin:$PATH
  export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"

  # Pyenv
  export PYENV_ROOT="$HOME/.pyenv"
  command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  # NOTE: do NOT add eval "$(pyenv init -)" or eval "$(pyenv virtualenv-init -)" (they slow the shell down a lot)

  # Python
  export PYTHONPATH=.
  export MYPYPATH=.

  # Vault (generated by eng-onboarding check-griphook script)
  export VAULT_ADDR=$(cat /Users/michael.uloth/.griphook/vault-addr)
  export VAULT_AUTH_METHOD=github
  export VAULT_AUTH_CREDS_PATH=/Users/michael.uloth/.griphook/github.pat
  export VAULT_TOKEN=$(cat /Users/michael.uloth/.griphook/vault-token)
  export GITHUB_TOKEN=$(cat $VAULT_AUTH_CREDS_PATH)

  # The next line updates PATH for the Google Cloud SDK.
  if [ -f '/Users/michael.uloth/google-cloud-sdk/path.zsh.inc' ]; then
  . '/Users/michael.uloth/google-cloud-sdk/path.zsh.inc';
  fi

  # The next line enables shell command completion for gcloud.
  if [ -f '/Users/michael.uloth/google-cloud-sdk/completion.zsh.inc' ]; then
  . '/Users/michael.uloth/google-cloud-sdk/completion.zsh.inc';
  fi

fi


