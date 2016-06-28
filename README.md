[LCLS Data Analysis at NERSC](https://confluence.slac.stanford.edu/display/PCDS/Running+at+NERSC)
===

[`psana python`](https://confluence.slac.stanford.edu/display/PSDM/LCLS+Data+Analysis) -A scalable software stack to analyze LCLS data can be used run at [NERSC](www.nersc.gov) using [Shifter](https://github.com/NERSC/shifter).
---


Currently this is only possible for "early access users" who have accounts at NERSC.

  - data are available at NERSC in this directory (the equivalent of `/reg/d/psdm`): /`global/project/projectdirs/lcls/d/psdm/`.  Set environment variable `SIT_PSDM_DATA` to this location so psana will be able to locate the data
  - ssh to cori.nersc.gov (the equivalent of a pslogin node)
  - information on the cori batch system ("slurm") is here
  - there are 32 cores on each cori node
  - to get to the equivalent of a "psana" node you should run an "interactive job" as described here

Example slurm script submitted with "sbatch <scriptname>" ("srun" is the cray-equivalent of "mpirun"):
```sh
#!/bin/bash -l
#SBATCH -p regular
#SBATCH -N 1
#SBATCH -t 01:00:00
#SBATCH -A lcls
#SBATCH --image=docker:registry.services.nersc.gov/psana:ana-0.17.4a
module load shifter
cd $HOME/shifter
srun -n 32 shifter ./myjob.csh
```

Where my job.csh looks like the usual psana-python command:

```tcsh
#!/bin/tcsh
source /reg/g/psdm/etc/ana_env.csh
cd $HOME/shifter
setenv SIT_PSDM_DATA /global/project/projectdirs/lcls/g/psdm/
python psana_io_benchmark.py exp=cxig3614:run=81
```

Getting An Account
---
*Note: this should only be necessary for expert developers.  Send mail to pcds-ana-l if you have questions.*
Apply for an account [HERE](http://www.nersc.gov/users/accounts/user-accounts/get-a-nersc-account/).

Useful NERSC Links
--- 
  - [Modules](http://www.nersc.gov/users/software/nersc-user-environment/modules/)
  - [Version control](http://www.nersc.gov/users/software/version-control-tools/)
  - [Libraries](http://www.nersc.gov/users/software/programming-libraries/)
  - [Globus for data transfer](http://www.nersc.gov/users/storage-and-file-systems/transferring-data)/globus-online/
  - [Queues](http://www.nersc.gov/users/queues/)
  - [X11/NX](http://www.nersc.gov/users/connecting-to-nersc/using-nx/) and [HERE](http://portal.nersc.gov/project/mpccc/nx/NX_Tutorial/M_Install.html)
