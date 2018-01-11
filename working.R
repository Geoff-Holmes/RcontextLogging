run_in_context <- function(script='', call=test_function, args_in=list(), rng_seed=0, git_check_timeout_time=1000, git_check_sleep_time=.25)
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
    # script is name of R code to run
    # rng_seed # seed value for random number generator
    # git_check_timeout_time=1000 # adjust if latency requires it : default 1000
    # git_check_sleep_time  = .25 # as above                      : default .25

    # library to enable interaction with git
    # install.packages("subprocess") # if not already installed
    require(subprocess)

    # useful function based on https://tolstoy.newcastle.edu.au/R/e5/help/08/11/6953.html
    stop_quietly <- function(msg, extra_msg='') {
        opt <- options(show.error.messages = FALSE)
        on.exit(options(opt))
        context$msg <<- sprintf("Aborted: %s", msg)
        cat(msg)
        cat(extra_msg)
        stop()
    }

    # initialise for saving context info
    context <- list()

    # get pc info
    pc_info <-Sys.info()
    context$pc_info <-sprintf("Running on %s, %s %s %s, machine: %s, logged in as %s",
    	pc_info["sysname"],pc_info["release"],pc_info["version"],
    	pc_info["machine"],pc_info["nodename"],pc_info["user"])

    # R and package info
    context$R_version<-R.version.string

    # get all curently loaded packages
    packages <- (.packages())
    for (k in 1:length(packages)) {
    pk <- packages[k]
    packages[k]<-sprintf("%s version %s", pk, packageVersion(pk))
    }
    context$package_info <- packages
    context$wd <- getwd()
    context$script <- script

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
        	context$git_status<-"working tree is confirmed clean"
        	# get current commit
        	process_write(handle, "git rev-parse HEAD\n")
            # give the subprocess a bit of time to complete
            Sys.sleep(git_check_sleep_time)
        	context$git_commit_ref<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)[2]
        	if (nchar(context$git_commit_ref)!=40) {
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

    context$rng_seed<-rng_seed

    # tidy up
    rm(list=c("pc_info", "packages"))

    context$start_time<-Sys.time()
    set.seed(rng_seed)
    {
        if (nchar(script))
        {
            source(script)
        }
        do.call(call, args_in)
    }
    context$end_time<-Sys.time()
}

test_function <- function()
{
    cat("Hello world!\n")
}

