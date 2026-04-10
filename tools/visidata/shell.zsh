########################
# ENVIRONMENT VARIABLES #
########################

# Not sure why this is necessary for the config to be picked up, but this does work
# Learned about this env var here: https://github.com/saulpw/visidata/issues/487#issuecomment-735643992
export VD_CONFIG="$HOME/.config/visidata/config.py"

###########
# ALIASES #
###########

# TODO: delete if it turns out to be unnecessary after installing visidata with pyarrow
# alias vd='uvx --with pyarrow visidata' # support opening parquet files
