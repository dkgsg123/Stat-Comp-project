library(styler)
style_file("code.R")

# ```{r line1, fig.width=5, fig.height=3}
# line_th <- ggplot(filament1, aes(x = Date, y = CAD_Weight)) +
#   geom_line() +
#   labs(title = "Variance of CAD Weight")
# print(line_th)
# ```

# ```{r line2, fig.width=5, fig.height=3}
# line_ac <- ggplot(filament1, aes(x = Date, y = Actual_Weight)) +
#   geom_line() +
#   labs(title = "Variance of Actual Weight")
# print(line_ac)
# ```

# ```{r cad_weight_bar}
# cad_w_hist <- ggplot(filament1, aes(x = CAD_Weight, fill = Material)) +
#   geom_histogram(binwidth = 1) +
#   facet_wrap(~ Material, scales = "free", ncol = 3) +
#   ylim(0, 5)
# print(cad_w_hist)
# ```

# ```{r material_bar, echo=FALSE}
# material_hist <- ggplot(filament1, aes(x = Material)) +
#   geom_bar(fill = "skyblue") +
#   labs(title = "Histogram of Material")
# print(material_hist)
# ```


# #
# axis.title = element_blank()

# ```{r opt results}
# exp(fit_theta$mode[3:4])
# ```