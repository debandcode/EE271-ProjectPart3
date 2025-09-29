module load base
module load vcs/S-2021.09-SP1

# Getting the Script Path
SCRIPT_PATH=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
export PATH=$SCRIPT_PATH/simulator/bin:$PATH