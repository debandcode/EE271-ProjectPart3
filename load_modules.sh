module purge
module load base
module load vcs/S-2021.09-SP1
module load dc_shell/S-2021.06-SP5-4

set SCRIPT_NAME = `lsof +p $$ | \grep -oE /.\*load_modules.sh`
set SCRIPT_PATH = `dirname $filename`
setenv PATH $SCRIPT_PATH/simulator/bin:$PATH
