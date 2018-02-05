run_with_logging <- function(
                                script='',
                                call='',
                                args_in=list(),
                                rng_seed=0,
                                save_file='',
                                git_check_timeout_time=1000,
                                git_check_sleep_time=.25
                            )
{
    # code in development for logging context info for research code
    # inspiration from Benureau (2018) Re-run, Repeat, Reproduce, Reuse, Replicate:
    # 	Transforming Code into Scientific Contributions
    # https://www.frontiersin.org/articles/10.3389/fninf.2017.00069/full
    #
    # geoff.r.holmes@sheffield.ac.uk
    #
    # 10/01/2018
    #
    # ARGUMENTS:
    # script                        : name of R code to run
    # call                          : name of any function to call - usually defined in script
    # args_in                       : any arguments to pass to call in a list
    # rng_seed                      : seed value for random number generator : default 0
    # git_check_timeout_time=1000   : adjust if latency requires it : default 1000
    # git_check_sleep_time  = .25   : as above                      : default .25

    # library to enable interaction with git
    # install.packages("subprocess") # if not already installed
    require(subprocess)

    # initialise for saving log_info info
    log_info <- list()
    xanadu   <- list()

    # get pc info as single string
    pc_info <-Sys.info()
    log_info$pc_info <-sprintf("Running on %s, %s %s %s, machine: %s, logged in as %s",
    	pc_info["sysname"],pc_info["release"],pc_info["version"],
    	pc_info["machine"],pc_info["nodename"],pc_info["user"])

    # R info and working directory
    log_info$R_version<-R.version.string
    log_info$working_dir <- getwd()

    # store git info
    log_info <- c(log_info, git_check())

    # store random seed and set
    log_info$rng_seed<-rng_seed
    set.seed(rng_seed)

    # nearly ready to roll
    log_info$start_time<-Sys.time()
    {
        # if user has supplied a script run script and any chosen function
        if (nchar(script))
        {
            log_info$script <- script
            source(script)
        }
        if (nchar(call))
        {
            log_info$call <- call
            log_info$args_in <-args_in
            xanadu$results<-do.call(call, args_in)
        } else {
            # if not just call test function defined below
            log_info$call<-'test_function'
            xanadu$results<-test_function()
        }
    }
    log_info$end_time<-Sys.time()

    # get info on all loaded packages
    packages <- (.packages())
    for (k in 1:length(packages)) {
        pk <- packages[k]
        packages[k]<-sprintf("%s : version %s", pk, packageVersion(pk))
    }
    log_info$package_info <- packages

    # create unique save name if none specified
    if(!nchar(save_file))
    {
        save_file<-sprintf("Result_%s_%s_%s", script, call, log_info$end_time)
        save_file<-gsub(':', '-', save_file)
        save_file<-gsub(' ', '_', save_file)
    }
    cc=0
    while (file.exists(paste(save_file,'.rds',sep='')))
    {
    	if (cc)
    	{
            inds<-unlist(gregexpr('_',save_file))
    	    save_file<-paste(substr(save_file,1,inds[length(inds)]), as.character(cc+2), sep='')
    	} else {
    	    save_file<-paste(save_file, "_2", sep='')
    	}
    	cc=cc+1
    }

    log_info$save_file<-save_file
    xanadu$log_info<-log_info
    class(xanadu)<-"runlog"
    saveRDS(xanadu, file=paste(save_file,'.rds',sep=''))
    cat("\nlog_info:\n\n")
    print(xanadu)
}

