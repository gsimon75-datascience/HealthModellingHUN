library(shiny)

shinyUI(
	fluidPage(
		titlePanel("Healthcare Modelling"),
		sidebarLayout(
			sidebarPanel(
				radioButtons("outcome", "Outcome",
					c("Births (per 1k)" = "births",
					  "Deaths (per 1k)" = "deaths")
				),
				checkboxGroupInput("pred_consumption", "Predictors - Consumption",
					c("Meat (kg/yr)" = "meat",
					  "Dairy (kg/yr)" = "dairy",
					  "Flour (kg/yr)" = "flour",
					  "Sugar (kg/yr)" = "sugar",
					  "Potato (kg/yr)" = "potato",
					  "Egg (pc/yr)" = "egg",
					  "Energy (kJ/dy)" = "energy"
					)
				),
				checkboxGroupInput("pred_healthcare", "Predictors - Healthcare",
					c("Doctors (per 10k)" = "doctors",
					  "Hospital Beds (per 10k)" = "hospital.beds"
					)
				),
				wellPanel(
				  helpText(a("Manual", href="https://gsimon75.github.io/HealthModellingHUN/")),
				  helpText(a("Project home", href="https://gsimon75.github.io/HealthModellingHUN"))
				)
			),
			mainPanel(
				conditionalPanel(condition="$('html').hasClass('shiny-busy')", style="text-align: center;", icon("spinner", "fa-3x fa-pulse")),
				plotOutput("model_plot"),
				h3("Fit results"),
				tableOutput("fit_result"),
				h3("Model attributes"),
				tableOutput("model_attrs")
			)
		)
	)
)
