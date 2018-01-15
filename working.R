git_checkout_time=1000
# open subprocess to interact with git
handle <- spawn_process("C:/Windows/System32/cmd.exe")
# add path to git to the environment variable PATH
process_write(handle, "PATH=%PATH%;C:\\Program Files\\Git\\cmd\n")

process_write(handle, "git diff-index HEAD\n")
process_write(handle, "git status\n")
process_write(handle, "git rev-parse HEAD\n")

continue_flag <- 1
lines_read <- 0
while(continue_flag)
{
    cat("\nNext while\n")
    tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)
    k<-1
    lines_read <- lines_read+length(tmp)
    print(tmp)
    cat('\n')
    while (k <= length(tmp))
    {
        if(gsub('[[:punct:] ]+', '', paste(getwd(), "git diff-index HEAD", sep=''))==gsub('[[:punct:] ]+', '', tmp[k]))
        {
            print(k)
            print(gsub('[[:punct:] ]+', '', paste(getwd(), "git diff-index HEAD", sep='')))
            print(gsub('[[:punct:] ]+', '', tmp[k]))
            k <- k + 1
            if (k > length(tmp))
            {
                tmp_read_flag <- 0
                while(!tmp_read_flag)
                {
                    cat("Waiting for subprocess ...\n")
                    tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=git_check_timeout_time)
                    tmp_read_flag <- length(tmp)
                    Sys.sleep(0.1)
                }
                lines_read <- lines_read+length(tmp)
                k<-1
            }
            print(tmp[k])
            continue_flag <- 0
            break
        } else {
            print(k)
            print(gsub('[[:punct:] ]+', '', tmp[k]))
            k <- k + 1
        }
    }
    print(lines_read)
}
