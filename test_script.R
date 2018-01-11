# test script to use with run_with_logging()
#
# geoff.r.holmes@sheffield.ac.uk

cat("Hello world!\nHowever, better to put everything inside a function call")

foo<-function(...)
{
    require(ggplot2)
    my_args<-as.numeric(paste(list(...)))
    mean_args<-mean(my_args)
    fig1_save_name<-'my_fig.pdf'
    qplot(my_args)
    ggsave(fig1_save_name)
    result<-list(mean=mean_args, fig1=fig1_save_name)
}
