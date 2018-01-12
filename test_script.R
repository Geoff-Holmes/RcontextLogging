# test script to use with run_with_logging()
#
# geoff.r.holmes@sheffield.ac.uk

cat("Hello world!\nHowever, better to put everything inside a function call")

foo<-function(N=10)
{
    require(ggplot2)
    dat<-runif(N)
    fig1_save_name<-'my_fig.pdf'
    p1<-qplot(1:N, dat)
    ggsave(fig1_save_name)
    return(list(data=dat, fig1=p1, fig1_file=fig1_save_name))
}
