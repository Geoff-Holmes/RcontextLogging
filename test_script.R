# test script

x<-runif(10)
plot(x)
cat("hello everyone!\n")

extra_stuff<-function(x1, x2)
{
    cat("\nextra processing\n\n")
    return(x1+x2)
}
