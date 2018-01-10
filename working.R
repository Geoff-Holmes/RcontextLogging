# code in development for logging context info for research code
# inspiration from Benureau (2018) Re-run, Repeat, Reproduce, Reuse, Replicate: 
# 	Transforming Code into Scientific Contributions
# https://www.frontiersin.org/articles/10.3389/fninf.2017.00069/full
#
# geoff.r.holmes@sheffield.ac.uk
#
# 10/01/2018

# library to enable interaction with git
library(subprocess)

# initialise for saving context info
context <- list()

# get pc info
pc_info <-Sys.info()
context$pc_info <-sprintf("Running on %s, %s %s %s, %s, logged in as %s",
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

# get git info
t_out=1000 # adjust if latency requires it
# open shell
handle <- spawn_process("C:/Windows/System32/cmd.exe")
# need to add git cmd folder to PATH could make it permanent
# assumed git cmd folder is at C:\Program Files\Git\
process_write(handle, "PATH=%PATH%;C:\\Program Files\\Git\\cmd\n")
# flush stdout
tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=t_out)
# check if git is clean
process_write(handle, "git diff-index HEAD\n")
# give the subprocess a bit of time to complete
Sys.sleep(1)
tmp<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=t_out)

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
	context$git_commit_ref<-process_read(handle, PIPE_STDOUT, flush=TRUE, timeout=t_out)[2]
	if (nchar(context$git_commit_ref)!=40) {
	    stop("git hash not stored correctly: please try again")
	}
    } else {
	stop("git is not clean: please commit first")
    }
} else {
    stop("git check did not complete properly: please try again")
}

# tidy up 
rm(list=c("pc_info", "packages"))

context$start_time=Sys.time()
{
	# actual code
}
context$end_time  =Sys.time()
