contextlogging

example usage:
library(devtools)
github_install("Geoff-Holmes/RcontextLogging")
library(RcontextLogging)

# it is assumed that you run the following within a git repo
# otherwise you will be prompted to create on first
# run test function
result<-run_with_logging()
# result will contain a result and information about 
# the PC and R version and packages used


# create file: test_script.R with contents ...
foo<-function(N=10)
{
    require(ggplot2)
    dat<-runif(N)
    fig1_save_name<-'my_fig.pdf'
    p1<-qplot(1:N, dat)
    ggsave(fig1_save_name)
    return(list(data=dat, fig1=p1, fig1_file=fig1_save_name))
    # actually there is no need to save the figure or the data separately
    # both can be recovered from the object p1 itself
    # get figure with: p1
    # get data with layer_data(p1) or ggplot_build(p1)
}

# log a run of the function foo in the file test_script.R
result<-run_with_logging(script="test_script.R", call="foo", args_in=list(N=5))

# full call spec
function (script = "", call = "", args_in = list(), rng_seed = 0, 
    save_file = "", git_check_timeout_time = 1000, git_check_sleep_time = 0.25)


