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

    # useful function based on https://tolstoy.newcastle.edu.au/R/e5/help/08/11/6953.html
    stop_quietly <- function(msg, extra_msg='') {
        opt <- options(show.error.messages = FALSE)
        on.exit(options(opt))
        cat(msg)
        cat(extra_msg)
        stop()
    }

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
    log_info$wd <- getwd()

    # get git info
    # open shell
    handle <- spawn_process("C:/Windows/System32/cmd.exe")
    # need to add git cmd folder to PATH could make it permanent
    # assumed git cmd folder is at C:\Program Files\Git\
    process_write(handle, "PATH=%PATH%;C:\\Program Files\\Git\\cmd\n")
    # flush stdout
    tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)
    # check if git is clean
    process_write(handle, "git diff-index HEAD\n")
    # give the subprocess a bit of time to complete
    Sys.sleep(git_check_sleep_time)
    tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)

    error_flag=0
    # check that stout was flushed and subprocess fully completed
    if (
        tmp[1]=="git diff-index HEAD" &
        gsub('[[:punct:] ]+', '', getwd())==gsub('[[:punct:] ]+', '', tmp[length(tmp)])
    	)
    {
        if (tmp[2]=="") # if not clean a diff hash should show here
        {
        	log_info$git_status<-"working tree is confirmed clean"
        	# check for untracked files
            process_write(handle, "git status\n")
            # give the subprocess a bit of time to complete
            Sys.sleep(git_check_sleep_time)
            tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)
            if (tmp[1]=="git status" &
                gsub('[[:punct:] ]+', '', getwd())==gsub('[[:punct:] ]+', '', tmp[length(tmp)]))
            {
                if (tmp[3]=="Untracked files:")
                {
                    u_in<-readline("WARNING: there are untracked files\nmake sure all used files are tracked\ndo you want to continue? : ")
                    if (!tolower(substr(u_in,1,1))=="n")
                    {
                        log_info$git_status=paste(log_info$git_status, "but there are untracked files")
                        Sys.sleep(0.5)
                        log_info$git_branch=tmp[2]
                    } else {
                        stop_quietly("user aborted due to untracked files")
                    }
                }
            } else {
                error_flag=1
            }
        	# get current commit
        	process_write(handle, "git rev-parse HEAD\n")
            # give the subprocess a bit of time to complete
            Sys.sleep(git_check_sleep_time)
        	log_info$git_commit_ref<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)[2]
        	if (nchar(log_info$git_commit_ref)!=40) {
        	    error_flag=1
        	}
        } else {
        	msg<-"git is not clean: please commit first"
            stop_quietly(msg)
        }
    } else {
        error_flag=1
    }
    if (error_flag)
    {
        msg<-"git check did not complete properly: please try again"
        extra_msg<-"\n\nif this problem persists try adjusting variables:\ngit_check_timeout_time and / or git_check_sleep_time"
        stop_quietly(msg, extra_msg)
    }

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
    saveRDS(xanadu, file=paste(save_file,'.rds',sep=''))
    cat("\nlog_info:\n\n")
    print(xanadu)
}

test_function <- function()
{
    msg<-"Test function called successfully!"
    cat(paste(msg, '\n'))
    return(msg)
}

