library(shiny)
library(readxl)
library(ggplot2)
library(lattice)
library(caret)
library(car)

# Health-related statistics modelling

# Source of Data: Hungarian Central Statistics Office (http://www.ksh.hu)

rds_file <- "hstat.rds"

if (file.exists(rds_file)) {
	hstat <- readRDS(rds_file)
} else {
	hstat <- data.frame(year=1960:2015)

	# health statistics: http://www.ksh.hu/docs/hun/xstadat/xstadat_hosszu/h_wdsd001a.html
	# databook: http://www.ksh.hu/apps/meta.objektum?p_lang=EN&p_menu_id=110&p_ot_id=100&p_obj_id=WNT
	if (!file.exists("h1_1.xls"))
		download.file("http://www.ksh.hu/docs/hun/xstadat/xstadat_hosszu/xls/h1_1.xls", "h1_1.xls")
	temp <- read_excel("h1_1.xls", skip=3, col_names=F)
	# outcomes: 1960<=year<=2015: births, deaths (per 1000 people)
	temp <- temp[(temp[,1] >= 1960) & (temp[,1] <= 2015), c(4,6)]
	hstat$births <- as.numeric(unlist(temp[,1]))
	hstat$deaths <- as.numeric(unlist(temp[,2]))

	# consumption per capita: http://www.ksh.hu/docs/hun/xstadat/xstadat_hosszu/h_qpt003.html
	# databook: http://www.ksh.hu/docs/hun/modsz/modsz22.html
	if (!file.exists("h2_2.xls"))
		download.file("http://www.ksh.hu/docs/hun/xstadat/xstadat_hosszu/xls/h2_2.xls", "h2_2.xls")
	temp <- read_excel("h2_2.xls", skip=4, col_names=F)
	# predictors: consumption of meat, dairy, flour, sugar, potato (kg/yr), egg (1/yr), energy (kJ/day) 
	temp <- temp[(temp[,1] >= 1960) & (temp[,1] <= 2015), ]
	hstat$meat <- unlist(temp[,2])
	hstat$dairy <- unlist(temp[,3])
	hstat$flour <- unlist(temp[,4])
	hstat$sugar <- unlist(temp[,5])
	hstat$potato <- unlist(temp[,6])
	hstat$egg <- unlist(temp[,7])
	hstat$energy <- unlist(temp[,8])

	# healthcare statistics: http://www.ksh.hu/docs/hun/xstadat/xstadat_hosszu/h_fea001.html
	# databook: http://www.ksh.hu/apps/meta.objektum?p_lang=EN&p_menu_id=110&p_ot_id=100&p_obj_id=FEA
	if (!file.exists("h2_4.xls"))
		download.file("http://www.ksh.hu/docs/hun/xstadat/xstadat_hosszu/xls/h2_4.xls", "h2_4.xls")
	temp <- read_excel("h2_4.xls", skip=2, col_names=F)
	# predictors: doctors, hospital beds (per 10k capita) 
	temp <- temp[(temp[,1] >= 1960) & (temp[,1] <= 2015), c(3, 5)]
	hstat$doctors <- unlist(temp[,1])
	hstat$hospital.beds <- unlist(temp[,2])

	saveRDS(hstat, rds_file)
}

shinyServer(
	function(input, output) {
		outcome <- reactive({
			input$outcome
		})
		predictors <- reactive({
			c(input$pred_consumption, input$pred_healthcare)
		})
		valid <- reactive({
			outcome() != "" && length(predictors()) > 0
		})
		fit <- reactive({
			if (valid()) {
				frm <- paste(outcome(), paste(collapse="+", predictors()), sep="~")
				train(as.formula(frm), data=hstat, method="lm")
			}
		})
		prediction <- reactive({
			if (valid()) {
				pred <- data.frame(hstat$year, predict(fit()$finalModel, hstat))
				colnames(pred) <- c("year", outcome())
				pred
			}
		})
		output$model_plot <- renderPlot({
			if (valid()) {
				ggplot(hstat, aes_string(x="year", y=outcome())) + geom_point() + geom_smooth(method="loess", data=prediction())
			}
		})

		output$fit_result <- renderTable({
			if (valid()) {
				fit()$results
			}
		})
		output$model_attrs <- renderTable({
			if (valid()) {
				coefficient <- fit()$finalModel$coefficients
				if (length(predictors()) >= 2) {
					vif <- vif(fit()$finalModel)
				} else {
					vif <- c()
				}

				data.frame(name=names(coefficient), coef=coefficient, VIF=c("-", vif))
			}
		})
	}
)

