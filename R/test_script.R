# test script to use with run_with_logging()
#
# geoff.r.holmes@sheffield.ac.uk

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
