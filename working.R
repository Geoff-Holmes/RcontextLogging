git_checkout_time=1000
# open subprocess to interact with git
handle <- spawn_process("C:/Windows/System32/cmd.exe")
# add path to git to the environment variable PATH
process_write(handle, "PATH=%PATH%;C:\\Program Files\\Git\\cmd\n")

process_write(handle, "git diff-index HEAD\n")
process_write(handle, "git status\n")
process_write(handle, "git rev-parse HEAD\n")

continue_flag <- 3
k <- lines_read <- 0 # k and lines_read are updated globally within calls to next read
while(continue_flag)
{
    cat(sprintf("Continue = %d\n", continue_flag))
    cat("\nNext while\n")
    tmp <- read_next()
    cat('\n')
    while (k <= length(tmp))
    {
        if (continue_flag>2)
        # check whether working tree is clean
        {
            if(gsub('[[:punct:] ]+', '', paste(getwd(), "git diff-index HEAD", sep=''))==gsub('[[:punct:] ]+', '', tmp[k]))
            {
                print(k)
                print(tmp[k])
                k <- k + 1
                if (k > length(tmp))
                {
                    tmp <- read_next()
                }
                if(tmp[k]=='')
                {
                    cat("Working tree is clean\nChecking for untracked files ...\n")
                    continue_flag <- continue_flag-1
                } else {
                    stop_quietly("Working tree is not clean")
                }
            }
            k <- k + 1
        } else {
            if (continue_flag>1)
            # check which branch and whether there are untracked files
            {
                stop("Bye")
            }
        }
    }
    cat(sprtinf("\n%d lines read\n", lines_read))
}
