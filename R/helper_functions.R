
# useful function based on https://tolstoy.newcastle.edu.au/R/e5/help/08/11/6953.html
stop_quietly <- function(msg, extra_msg='') {
    opt <- options(show.error.messages = FALSE)
    on.exit(options(opt))
    cat(msg)
    cat(extra_msg)
    stop()
}

git_check <- function(ignore_untracked=F)
{
    git_check_timeout_time=1000
    untracked <- FALSE
    # open subprocess to interact with git
    if (tolower(.Platform$OS.type) == "windows")
    {
        handle <- spawn_process("C:/Windows/System32/cmd.exe")
        # add path to git to the environment variable PATH
        process_write(handle, "PATH=%PATH%;C:\\Program Files\\Git\\cmd\n")
        # send 3 git commands to subprocess
        git_cmds<-c("git diff-index HEAD", "git status", "git rev-parse HEAD")
        for (k in 1:length(git_cmds))
        {
            process_write(handle, sprintf("%s\n", git_cmds[k]))
        }

        # last line collected from STDOUT should be current working directory
        # remove punctuation  and spaces to avoid confusion
        subproc_output<-"dummy"
        cc <- 0
        while(gsub('[[:punct:] ]+', '', getwd())!=gsub('[[:punct:] ]+', '', subproc_output[length(subproc_output)]))
        {
            tmp_read_flag <- 0
            # keep reading until lines are received but abort after 33 attempts
            while(!tmp_read_flag)
            {
                cc<-cc+1
                if (!(cc %% 10)) { cat("Sorry still waiting for subprocess output\n")}
                if (cc>33) { stop_quietly("Lost output from subprocess : please try again")}
                cat("Waiting for subprocess ...\n")
                tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)
                tmp_read_flag <- length(tmp)
                Sys.sleep(0.1)
            }
    #        print(tmp)
            subproc_output<-c(subproc_output, tmp)
    #        print(subproc_output)
        }

        # find where output from each command starts
        inds<-grep(paste(git_cmds,collapse='|'), subproc_output)

        if(subproc_output[inds[1]+1]!='')
        {
            stop_quietly("Working tree is not clean : please commit first\n")
        }

        untracked <- any(subproc_output=="Untracked files:")
        hash      <- subproc_output[inds[3]+1]
        branch    <- subproc_output[inds[2]+1]

    } else {
        # code for linux
        handle <- spawn_process("/bin/sh")
        process_write(handle, "git diff\n")
        tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)
        if(length(tmp))
        {
            stop_quietly("Working tree is not clean : please commit first\n")
        }
        process_write(handle, "git status\n")
        tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)
        branch<-tmp[1]
        untracked<-tmp[2]!="nothing to commit, working directory clean"
        process_write(handle, "git rev-parse HEAD\n")
        tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)
        hash<-tmp[1]
    }
    {
    tmp<-process_read(handle, PIPE_STDERR, flush=TRUE, timeout=git_check_timeout_time)
    if(length(tmp))
        stop_quietly("No git repository found: please create one first\n")

    }

    # initialise for results
    status=list()
    cat("Working tree is clean\n") # stopped earlier if not
    status$tree<-"Working tree is clean"
    if(untracked)
    {
        if(!ignore_untracked)
        {
            u_in<-readline("There are untracked files present : do you wish to continue? [Y/n] ")
            if(tolower(u_in)=="n")
            {
                stop_quietly("Aborting")
            }
        }
        status$tree<-paste(status$tree, ": But there are untracked files")
    } else {
        cat("There are no untracked files\n")
        status$tree<-paste(status$tree, ": And there are no untracked files")
    }

    cat("Current git hash is :\n", hash, "\n")
    status$current_commit <- hash
    status$branch <- branch

    status
}

test_function <- function()
{
    msg<-"Test function called successfully!"
    cat(paste(msg, '\n'))
    return(msg)
}

# read lines available in STDOUT from subproceess
# the code in this function has been moved within git_check because making a sub-function call wasn't working
#read_next <- function()
#{
#    tmp_read_flag <- 0
#    cc <- 0
#    # keep reading until lines are received but abort after 10 attempts
#    while(!tmp_read_flag & cc<10)
#    {
#        cc<-cc+1
#        cat("Waiting for subprocess ...\n")
#        tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)
#        tmp_read_flag <- length(tmp)
#        Sys.sleep(0.1)
#    }
#    print(tmp)
#    tmp
#}
