read_next <- function()
{
    tmp_read_flag <- 0
    while(!tmp_read_flag)
    {
        cat("Waiting for subprocess ...\n")
        tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)
        tmp_read_flag <- length(tmp)
        Sys.sleep(0.1)
    }
    lines_read <<- lines_read+length(tmp)
    k <<- 1
    print(tmp)
    tmp
}

# useful function based on https://tolstoy.newcastle.edu.au/R/e5/help/08/11/6953.html
stop_quietly <- function(msg, extra_msg='') {
    opt <- options(show.error.messages = FALSE)
    on.exit(options(opt))
    cat(msg)
    cat(extra_msg)
    stop()
}
