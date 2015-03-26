data <- read.table("ARCHIE-expanding-area.input", header=T, sep="\t")

y_range = range(250, data$runtime)
x_range = range(data$processes)

plot_colours <- c("blue", "red")

png(filename="ARCHIE-expanding-area.png", height=400, width=500, bg="white")

plot(data$processes, data$runtime, log="xy",type="l", col=plot_colours[1], ylim=y_range, xlim=x_range, axes=TRUE, ann=FALSE)

abline(v=c(1, 2, 5, 10, 20, 50, 100), col="grey10", lty="dotted")
abline(h=c(180, 200, 220, 240), col="grey10", lty="dotted")

title(main="ARCHIE Expanding Area")
title(xlab="Process count")
title(ylab="Runtime (s)")

box()
