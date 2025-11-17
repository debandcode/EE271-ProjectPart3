#!/bin/csh -f

cd /home/users/shern/Documents/EE271/Project/EE271-ProjectPart2/equivalence_testing

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/cad/synopsys/vcs/S-2021.09-SP1/linux64/bin/vcselab $* \
    -o \
    simv \
    -nobanner \

cd -

