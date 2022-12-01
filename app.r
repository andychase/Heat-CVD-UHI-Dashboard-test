
require(tidycensus)
require(shinydashboard)
require(leaflet)
require(htmlwidgets)
require(bslib)
require(sf)
require(plotly)
require(forcats)
require(shinyWidgets)
require(listviewer)
require(jsonlite)
require(dlnm)
require(DT)
require(dplyr)
require(shinycssloaders)

# Define color palettes
palettes <- data.frame("Variable" = c("uhi","uhiq","hosp","temp","range","temp.99"), 
"Color" = c("RdYlBu","RdYlBu","PuRd","RdYlBu","Purple-Green","Heat"))
palettes_cbsa <- data.frame("Variable" = c("rr.99","an.heat","af.heat","mht","ar.heat"), 
"Color" = c("Geyser","Fall","TealRose","Temps","ArmyRose"))
sub_palettes <- list("PrimaryAll" = "black",
					"UHIIAll" = c("#5385BC","#E34D34"),
					"PrimaryCKD" = c("#CC99BB","#771155"),
					"PrimaryDiabetes" = c("#77AADD","#114477"),
					"UHIICKD" = c("#5385BC","#E34D34","#5385BC","#E34D34"),
					"UHIIDiabetes" = c("#5385BC","#E34D34","#5385BC","#E34D34"),
					"PrimaryRace" = c("#117744","#88CCAA"),
					"PrimarySex" = c( "#777711","#DDDD77"),
					"UHIIRace" = c("#5385BC","#E34D34","#5385BC","#E34D34"),
					"UHIISex" = c("#5385BC","#E34D34","#5385BC","#E34D34"),
					"PrimaryAge" = c("#771122", "#AA4455", "#DD7788"),
					"UHIIAge" = c("#5385BC","#E34D34","#5385BC","#E34D34","#5385BC","#E34D34")
					)

# Read in datasets
zips_shape <- readRDS('./data/simp_05_zip_shapes_with_data.RDS')
cbsa_all <- readRDS('./data/cbsa_rr_an_results.RDS')
cbsa_all$Koppen.Simple <- gsub(",.*$","",cbsa_all$Koppen.Description)
cbsas_shape_full <- readRDS('./data/cbsa_shapes_with_data.RDS') 
load('./data/cbsa_pred_tmean.Rdata')
pooled <- readRDS('./data/full_list_pooled_ests.RDS')
pooled.99 <- readRDS('./data/full_list_pooled_ests_99.RDS')
sub_rr_af_an <- readRDS('./data/subgroup_all_results.RDS')

# Define HTML style for dashboard
box.style <- ".box.box-solid.box-primary>.box-header {
color:#fff;
background:#F8F8F8}
.box.box-solid.box-primary{
border-bottom-color:#F8F8F8;
border-left-color:#F8F8F8;
border-right-color:#F8F8F8;
border-top-color:#F8F8F8;}"

tabbox.style <- ".nav-tabs {background: #f4f4f4;}
.nav-tabs-custom .nav-tabs li.active:hover a, .nav-tabs-custom .nav-tabs li.active a {background-color: #fff;
	   border-color: #fff;}
.nav-tabs-custom .nav-tabs li.active {border-top-color: 
			  #314a6d;}"

ui <- fluidPage(
tags$html(class = "no-js", lang="en"),
tags$head	(
			HTML(
				"<!-- Google Tag Manager -->
				<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
				new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
				j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
				'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
				})(window,document,'script','dataLayer','GTM-L8ZB');</script>
				<!-- End Google Tag Manager -->
				"
				),
			tags$meta(charset="utf-8"),
			tags$meta(property="og:site_name", content="US EPA"),
			#tags$link(rel = "stylesheet", type = "text/css", href = "css/uswds.css"),
			tags$link(rel = "stylesheet", type = "text/css", href = "https://cdnjs.cloudflare.com/ajax/libs/uswds/3.0.0-beta.3/css/uswds.min.css", integrity="sha512-ZKvR1/R8Sgyx96aq5htbFKX84hN+zNXN73sG1dEHQTASpNA8Pc53vTbPsEKTXTZn9J4G7R5Il012VNsDEReqCA==", crossorigin="anonymous", referrerpolicy="no-referrer"),
			tags$meta(property="og:url", content="https://www.epa.gov/themes/epa_theme/pattern-lab/.markup-only.html"),
			tags$link(rel="canonical", href="https://www.epa.gov/themes/epa_theme/pattern-lab/.markup-only.html"),
			tags$link(rel="shortlink", href="https://www.epa.gov/themes/epa_theme/pattern-lab/.markup-only.html"),
			tags$meta(property="og:url", content="https://www.epa.gov/themes/epa_theme/pattern-lab/.markup-only.html"),
			tags$meta(property="og:image", content="https://www.epa.gov/sites/all/themes/epa/img/epa-standard-og.jpg"),
			tags$meta(property="og:image:width", content="1200"),
			tags$meta(property="og:image:height", content="630"),
			tags$meta(property="og:image:alt", content="U.S. Environmental Protection Agency"),
			tags$meta(name="twitter:card", content="summary_large_image"),
			tags$meta(name="twitter:image:alt", content="U.S. Environmental Protection Agency"),
			tags$meta(name="twitter:image:height", content="600"),
			tags$meta(name="twitter:image:width", content="1200"),
			tags$meta(name="twitter:image", content="https://www.epa.gov/sites/all/themes/epa/img/epa-standard-twitter.jpg"),
			tags$meta(name="MobileOptimized", content="width"),
			tags$meta(name="HandheldFriendly", content="true"),
			tags$meta(name="viewport", content="width=device-width, initial-scale=1.0"),
			tags$meta(`http-equiv`="x-ua-compatible", content="ie=edge"),
			tags$title('Heat CVD UHI Dashboard | US EPA'),
			tags$link(rel="icon", type="image/x-icon", href="https://www.epa.gov/themes/epa_theme/images/favicon.ico"),
			tags$meta(name="msapplication-TileColor", content="#FFFFFF"),
			tags$meta(name="msapplication-TileImage", content="https://www.epa.gov/themes/epa_theme/images/favicon-144.png"),
			tags$meta(name="application-name", content=""),
			tags$meta(name="msapplication-config", content="https://www.epa.gov/themes/epa_theme/images/ieconfig.xml"),
			tags$link(rel="apple-touch-icon-precomposed", sizes="196x196", href="https://www.epa.gov/themes/epa_theme/images/favicon-196.png"),
			tags$link(rel="apple-touch-icon-precomposed", sizes="152x152", href="https://www.epa.gov/themes/epa_theme/images/favicon-152.png"),
			tags$link(rel="apple-touch-icon-precomposed", sizes="144x144", href="https://www.epa.gov/themes/epa_theme/images/favicon-144.png"),
			tags$link(rel="apple-touch-icon-precomposed", sizes="120x120", href="https://www.epa.gov/themes/epa_theme/images/favicon-120.png"),
			tags$link(rel="apple-touch-icon-precomposed", sizes="114x114", href="https://www.epa.gov/themes/epa_theme/images/favicon-114.png"),
			tags$link(rel="apple-touch-icon-precomposed", sizes="72x72", href="https://www.epa.gov/themes/epa_theme/images/favicon-72.png"),
			tags$link(rel="apple-touch-icon-precomposed", href="https://www.epa.gov/themes/epa_theme/images/favicon-180.png"),
			tags$link(rel="icon", href="https://www.epa.gov/themes/epa_theme/images/favicon-32.png", sizes="32x32"),
			tags$link(rel="preload", href="https://www.epa.gov/themes/epa_theme/fonts/source-sans-pro/sourcesanspro-regular-webfont.woff2", as="font", crossorigin="anonymous"),
			tags$link(rel="preload", href="https://www.epa.gov/themes/epa_theme/fonts/source-sans-pro/sourcesanspro-bold-webfont.woff2", as="font", crossorigin="anonymous"),
			tags$link(rel="preload", href="https://www.epa.gov/themes/epa_theme/fonts/merriweather/Latin-Merriweather-Bold.woff2", as="font", crossorigin="anonymous"),
			tags$link(rel="stylesheet", media="all", href="https://www.epa.gov/core/themes/stable/css/system/components/ajax-progress.module.css?r6lsex"),
			tags$link(rel="stylesheet", media="all", href="https://www.epa.gov/core/themes/stable/css/system/components/autocomplete-loading.module.css?r6lsex" ),
			tags$link(rel="stylesheet", media="all", href="https://www.epa.gov/core/themes/stable/css/system/components/js.module.css?r6lsex"),
			tags$link(rel="stylesheet", media="all", href="https://www.epa.gov/core/themes/stable/css/system/components/sticky-header.module.css?r6lsex"),
			tags$link(rel="stylesheet", media="all", href="https://www.epa.gov/core/themes/stable/css/system/components/system-status-counter.css?r6lsex"),
			tags$link(rel="stylesheet", media="all", href="https://www.epa.gov/core/themes/stable/css/system/components/system-status-report-counters.css?r6lsex"),
			tags$link(rel="stylesheet", media="all", href="https://www.epa.gov/core/themes/stable/css/system/components/system-status-report-general-info.css?r6lsex"),
			tags$link(rel="stylesheet", media="all", href="https://www.epa.gov/core/themes/stable/css/system/components/tabledrag.module.css?r6lsex"),
			tags$link(rel="stylesheet", media="all", href="https://www.epa.gov/core/themes/stable/css/system/components/tablesort.module.css?r6lsex"),
			tags$link(rel="stylesheet", media="all", href="https://www.epa.gov/core/themes/stable/css/system/components/tree-child.module.css?r6lsex"),
			tags$link(rel="stylesheet", media="all", href="https://www.epa.gov/themes/epa_theme/css/styles.css?r6lsex"),
			tags$link(rel="stylesheet", media="all", href="https://www.epa.gov/themes/epa_theme/css-lib/colorbox.min.css?r6lsex"),
			
			tags$script(src = 'https://cdnjs.cloudflare.com/ajax/libs/uswds/3.0.0-beta.3/js/uswds-init.min.js'),
			#fix container-fluid that boostrap RShiny uses
			tags$style(HTML(
			'.container-fluid {
			padding-right: 0;
			padding-left: 0;
			margin-right: 0;
			margin-left: 0;
			}
			.tab-content {
			margin-right: 30px;
			margin-left: 30px;
			}'
			))
			),
tags$body(class="path-themes not-front has-wide-template", id="top",
tags$script(src = 'https://cdnjs.cloudflare.com/ajax/libs/uswds/3.0.0-beta.3/js/uswds.min.js')),

# Site Header
HTML(
	'<div class="skiplinks" role="navigation" aria-labelledby="skip-to-main">
	<a id="skip-to-main" href="#main" class="skiplinks__link visually-hidden focusable">Skip to main content</a>
	</div>

	<!-- Google Tag Manager (noscript) -->
	<noscript><iframe src=https://www.googletagmanager.com/ns.html?id=GTM-L8ZB
	height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
	<!-- End Google Tag Manager (noscript) -->

	<div class="dialog-off-canvas-main-canvas" data-off-canvas-main-canvas>
	<section class="usa-banner" aria-label="Official government website">
	<div class="usa-accordion">
	<header class="usa-banner__header">
	<div class="usa-banner__inner">
	<div class="grid-col-auto">
	<img class="usa-banner__header-flag" src="https://www.epa.gov/themes/epa_theme/images/us_flag_small.png" alt="U.S. flag" />
	</div>
	<div class="grid-col-fill tablet:grid-col-auto">
	<p class="usa-banner__header-text">An official website of the United States government</p>
	<p class="usa-banner__header-action" aria-hidden="true">Here’s how you know</p>
	</div>
	<button class="usa-accordion__button usa-banner__button" aria-expanded="false" aria-controls="gov-banner">
	<span class="usa-banner__button-text">Here’s how you know</span>
	</button>
	</div>
	</header>
	<div class="usa-banner__content usa-accordion__content" id="gov-banner">
	<div class="grid-row grid-gap-lg">
	<div class="usa-banner__guidance tablet:grid-col-6">
	<img class="usa-banner__icon usa-media-block__img" src="https://www.epa.gov/themes/epa_theme/images/icon-dot-gov.svg" alt="Dot gov">
	<div class="usa-media-block__body">
	<p>
	<strong>Official websites use .gov</strong>
	<br> A <strong>.gov</strong> website belongs to an official government organization in the United States.
	</p>
	</div>
	</div>
	<div class="usa-banner__guidance tablet:grid-col-6">
	<img class="usa-banner__icon usa-media-block__img" src="https://www.epa.gov/themes/epa_theme/images/icon-https.svg" alt="HTTPS">
	<div class="usa-media-block__body">
	<p>
	<strong>Secure .gov websites use HTTPS</strong>
	<br> A <strong>lock</strong> (<span class="icon-lock"><svg xmlns="http://www.w3.org/2000/svg" width="52" height="64" viewBox="0 0 52 64" class="usa-banner__lock-image" role="img" aria-labelledby="banner-lock-title banner-lock-description"><title id="banner-lock-title">Lock</title><desc id="banner-lock-description">A locked padlock</desc><path fill="#000000" fill-rule="evenodd" d="M26 0c10.493 0 19 8.507 19 19v9h3a4 4 0 0 1 4 4v28a4 4 0 0 1-4 4H4a4 4 0 0 1-4-4V32a4 4 0 0 1 4-4h3v-9C7 8.507 15.507 0 26 0zm0 8c-5.979 0-10.843 4.77-10.996 10.712L15 19v9h22v-9c0-6.075-4.925-11-11-11z"/></svg></span>) or <strong>https://</strong> means you’ve safely connected to the .gov website. Share sensitive information only on official, secure websites.
	</p>
	</div>
	</div>
	</div>
	</div>
	</div>
	</section>
	<div>
	<div class="js-view-dom-id-epa-alerts--public">
	<noscript>
	<div class="usa-site-alert usa-site-alert--info">
	<div class="usa-alert">
	<div class="usa-alert__body">
	<div class="usa-alert__text">
	<p>JavaScript appears to be disabled on this computer. Please <a href="/alerts">click here to see any active alerts</a>.</p>
	</div>
	</div>
	</div>
	</div>
	</noscript>
	</div>
	</div>
	<header class="l-header">
	<div class="usa-overlay"></div>
	<div class="l-constrain">
	<div class="l-header__navbar">
	<div class="l-header__branding">
	<a class="site-logo" href="/" aria-label="Home" title="Home" rel="home">
	<span class="site-logo__image">
	<svg class="site-logo__svg" viewBox="0 0 1061 147" aria-hidden="true" xmlns="http://www.w3.org/2000/svg">
	<path d="M112.8 53.5C108 72.1 89.9 86.8 69.9 86.8c-20.1 0-38-14.7-42.9-33.4h.2s9.8 10.3-.2 0c3.1 3.1 6.2 4.4 10.7 4.4s7.7-1.3 10.7-4.4c3.1 3.1 6.3 4.5 10.9 4.4 4.5 0 7.6-1.3 10.7-4.4 3.1 3.1 6.2 4.4 10.7 4.4 4.5 0 7.7-1.3 10.7-4.4 3.1 3.1 6.3 4.5 10.9 4.4 4.3 0 7.4-1.2 10.5-4.3zM113.2 43.5c0-24-19.4-43.5-43.3-43.5-24 0-43.5 19.5-43.5 43.5h39.1c-4.8-1.8-8.1-6.3-8.1-11.6 0-7 5.7-12.5 12.5-12.5 7 0 12.7 5.5 12.7 12.5 0 5.2-3.1 9.6-7.6 11.6h38.2zM72.6 139.3c.7-36.9 29.7-68.8 66.9-70 0 37.2-30 68-66.9 70zM67.1 139.3c-.7-36.9-29.7-68.8-67.1-70 0 37.2 30.2 68 67.1 70zM240 3.1h-87.9v133.1H240v-20.4h-60.3v-36H240v-21h-60.3v-35H240V3.1zM272.8 58.8h27.1c9.1 0 15.2-8.6 15.1-17.7-.1-9-6.1-17.3-15.1-17.3h-25.3v112.4h-27.8V3.1h62.3c20.2 0 35 17.8 35.2 38 .2 20.4-14.8 38.7-35.2 38.7h-36.3v-21zM315.9 136.2h29.7l12.9-35h54.2l-8.1-21.9h-38.4l18.9-50.7 39.2 107.6H454L400.9 3.1h-33.7l-51.3 133.1zM473.3.8v22.4c0 1.9.2 3.3.5 4.3s.7 1.7 1 2.2c1.2 1.4 2.5 2.4 3.9 2.9 1.5.5 2.8.7 4.1.7 2.4 0 4.2-.4 5.5-1.3 1.3-.8 2.2-1.8 2.8-2.9.6-1.1.9-2.3 1-3.4.1-1.1.1-2 .1-2.6V.8h4.7v24c0 .7-.1 1.5-.4 2.4-.3 1.8-1.2 3.6-2.5 5.4-1.8 2.1-3.8 3.5-6 4.2-2.2.6-4 .9-5.3.9-1.8 0-3.8-.3-6.2-1.1-2.4-.8-4.5-2.3-6.2-4.7-.5-.8-1-1.8-1.4-3.2-.4-1.3-.6-3.3-.6-5.9V.8h5zM507.5 14.5v-2.9l4.6.1-.1 4.1c.2-.3.4-.7.8-1.2.3-.5.8-.9 1.4-1.4.6-.5 1.4-.9 2.3-1.3.9-.3 2.1-.5 3.4-.4.6 0 1.4.1 2.4.3.9.2 1.9.6 2.9 1.2s1.8 1.5 2.4 2.6c.6 1.2.9 2.8.9 4.7l-.4 17-4.6-.1.4-16c0-.9 0-1.7-.2-2.4-.1-.7-.5-1.3-1.1-1.9-1.2-1.2-2.6-1.8-4.3-1.8-1.7 0-3.1.5-4.4 1.7-1.3 1.2-2 3.1-2.1 5.7l-.3 14.5-4.5-.1.5-22.4zM537.2.9h5.5V6h-5.5V.9m.5 10.9h4.6v25.1h-4.6V11.8zM547.8 11.7h4.3V6.4l4.5-1.5v6.8h5.4v3.4h-5.4v15.1c0 .3 0 .6.1 1 0 .4.1.7.4 1.1.2.4.5.6 1 .8.4.3 1 .4 1.8.4 1 0 1.7-.1 2.2-.2V37c-.9.2-2.1.3-3.8.3-2.1 0-3.6-.4-4.6-1.2-1-.8-1.5-2.2-1.5-4.2V15.1h-4.3v-3.4zM570.9 25.2c-.1 2.6.5 4.8 1.7 6.5 1.1 1.7 2.9 2.6 5.3 2.6 1.5 0 2.8-.4 3.9-1.3 1-.8 1.6-2.2 1.8-4h4.6c0 .6-.2 1.4-.4 2.3-.3 1-.8 2-1.7 3-.2.3-.6.6-1 1-.5.4-1 .7-1.7 1.1-.7.4-1.5.6-2.4.8-.9.3-2 .4-3.3.4-7.6-.2-11.3-4.5-11.3-12.9 0-2.5.3-4.8 1-6.8s2-3.7 3.8-5.1c1.2-.8 2.4-1.3 3.7-1.6 1.3-.2 2.2-.3 3-.3 2.7 0 4.8.6 6.3 1.6s2.5 2.3 3.1 3.9c.6 1.5 1 3.1 1.1 4.6.1 1.6.1 2.9 0 4h-17.5m12.9-3v-1.1c0-.4 0-.8-.1-1.2-.1-.9-.4-1.7-.8-2.5s-1-1.5-1.8-2c-.9-.5-2-.8-3.4-.8-.8 0-1.5.1-2.3.3-.8.2-1.5.7-2.2 1.3-.7.6-1.2 1.3-1.6 2.3-.4 1-.7 2.2-.8 3.6h13zM612.9.9h4.6V33c0 1 .1 2.3.2 4h-4.6l-.1-4c-.2.3-.4.7-.7 1.2-.3.5-.8 1-1.4 1.5-1 .7-2 1.2-3.1 1.4l-1.5.3c-.5.1-.9.1-1.4.1-.4 0-.8 0-1.3-.1s-1.1-.2-1.7-.3c-1.1-.3-2.3-.9-3.4-1.8s-2.1-2.2-2.9-3.8c-.8-1.7-1.2-3.9-1.2-6.6.1-4.8 1.2-8.3 3.4-10.5 2.1-2.1 4.7-3.2 7.6-3.2 1.3 0 2.4.2 3.4.5.9.3 1.6.7 2.2 1.2.6.4 1 .9 1.3 1.4.3.5.6.8.7 1.1V.9m0 23.1c0-1.9-.2-3.3-.5-4.4-.4-1.1-.8-2-1.4-2.6-.5-.7-1.2-1.3-2-1.8-.9-.5-2-.7-3.3-.7-1.7 0-2.9.5-3.8 1.3-.9.8-1.6 1.9-2 3.1-.4 1.2-.7 2.3-.7 3.4-.1 1.1-.2 1.9-.1 2.4 0 1.1.1 2.2.3 3.4.2 1.1.5 2.2 1 3.1.5 1 1.2 1.7 2 2.3.9.6 2 .9 3.3.9 1.8 0 3.2-.5 4.2-1.4 1-.8 1.7-1.8 2.1-3 .4-1.2.7-2.4.8-3.4.1-1.4.1-2.1.1-2.6zM643.9 26.4c0 .6.1 1.3.3 2.1.1.8.5 1.6 1 2.3.5.8 1.4 1.4 2.5 1.9s2.7.8 4.7.8c1.8 0 3.3-.3 4.4-.8 1.1-.5 1.9-1.1 2.5-1.8.6-.7 1-1.5 1.1-2.2.1-.7.2-1.2.2-1.7 0-1-.2-1.9-.5-2.6-.4-.6-.9-1.2-1.6-1.6-1.4-.8-3.4-1.4-5.9-2-4.9-1.1-8.1-2.2-9.5-3.2-1.4-1-2.3-2.2-2.9-3.5-.6-1.2-.8-2.4-.8-3.6.1-3.7 1.5-6.4 4.2-8.1 2.6-1.7 5.7-2.5 9.1-2.5 1.3 0 2.9.2 4.8.5 1.9.4 3.6 1.4 5 3 .5.5.9 1.1 1.2 1.7.3.5.5 1.1.6 1.6.2 1.1.3 2.1.3 2.9h-5c-.2-2.2-1-3.7-2.4-4.5-1.5-.7-3.1-1.1-4.9-1.1-5.1.1-7.7 2-7.8 5.8 0 1.5.5 2.7 1.6 3.5 1 .8 2.6 1.4 4.7 1.9 4 1 6.7 1.8 8.1 2.2.8.2 1.4.5 1.8.7.5.2 1 .5 1.4.9.8.5 1.4 1.1 1.9 1.8s.8 1.4 1.1 2.1c.3 1.4.5 2.5.5 3.4 0 3.3-1.2 6-3.5 8-2.3 2.1-5.8 3.2-10.3 3.3-1.4 0-3.2-.3-5.4-.8-1-.3-2-.7-3-1.2-.9-.5-1.8-1.2-2.5-2.1-.9-1.4-1.5-2.7-1.7-4.1-.3-1.3-.4-2.4-.3-3.2h5zM670 11.7h4.3V6.4l4.5-1.5v6.8h5.4v3.4h-5.4v15.1c0 .3 0 .6.1 1 0 .4.1.7.4 1.1.2.4.5.6 1 .8.4.3 1 .4 1.8.4 1 0 1.7-.1 2.2-.2V37c-.9.2-2.1.3-3.8.3-2.1 0-3.6-.4-4.6-1.2-1-.8-1.5-2.2-1.5-4.2V15.1H670v-3.4zM705.3 36.9c-.3-1.2-.5-2.5-.4-3.7-.5 1-1.1 1.8-1.7 2.4-.7.6-1.4 1.1-2 1.4-1.4.5-2.7.8-3.7.8-2.8 0-4.9-.8-6.4-2.2-1.5-1.4-2.2-3.1-2.2-5.2 0-1 .2-2.3.8-3.7.6-1.4 1.7-2.6 3.5-3.7 1.4-.7 2.9-1.2 4.5-1.5 1.6-.1 2.9-.2 3.9-.2s2.1 0 3.3.1c.1-2.9-.2-4.8-.9-5.6-.5-.6-1.1-1.1-1.9-1.3-.8-.2-1.6-.4-2.3-.4-1.1 0-2 .2-2.6.5-.7.3-1.2.7-1.5 1.2-.3.5-.5.9-.6 1.4-.1.5-.2.9-.2 1.2h-4.6c.1-.7.2-1.4.4-2.3.2-.8.6-1.6 1.3-2.5.5-.6 1-1 1.7-1.3.6-.3 1.3-.6 2-.8 1.5-.4 2.8-.6 4.2-.6 1.8 0 3.6.3 5.2.9 1.6.6 2.8 1.6 3.4 2.9.4.7.6 1.4.7 2 .1.6.1 1.2.1 1.8l-.2 12c0 1 .1 3.1.4 6.3h-4.2m-.5-12.1c-.7-.1-1.6-.1-2.6-.1h-2.1c-1 .1-2 .3-3 .6s-1.9.8-2.6 1.5c-.8.7-1.2 1.7-1.2 3 0 .4.1.8.2 1.3s.4 1 .8 1.5.9.8 1.6 1.1c.7.3 1.5.5 2.5.5 2.3 0 4.1-.9 5.2-2.7.5-.8.8-1.7 1-2.7.1-.9.2-2.2.2-4zM714.5 11.7h4.3V6.4l4.5-1.5v6.8h5.4v3.4h-5.4v15.1c0 .3 0 .6.1 1 0 .4.1.7.4 1.1.2.4.5.6 1 .8.4.3 1 .4 1.8.4 1 0 1.7-.1 2.2-.2V37c-.9.2-2.1.3-3.8.3-2.1 0-3.6-.4-4.6-1.2-1-.8-1.5-2.2-1.5-4.2V15.1h-4.3v-3.4zM737.6 25.2c-.1 2.6.5 4.8 1.7 6.5 1.1 1.7 2.9 2.6 5.3 2.6 1.5 0 2.8-.4 3.9-1.3 1-.8 1.6-2.2 1.8-4h4.6c0 .6-.2 1.4-.4 2.3-.3 1-.8 2-1.7 3-.2.3-.6.6-1 1-.5.4-1 .7-1.7 1.1-.7.4-1.5.6-2.4.8-.9.3-2 .4-3.3.4-7.6-.2-11.3-4.5-11.3-12.9 0-2.5.3-4.8 1-6.8s2-3.7 3.8-5.1c1.2-.8 2.4-1.3 3.7-1.6 1.3-.2 2.2-.3 3-.3 2.7 0 4.8.6 6.3 1.6s2.5 2.3 3.1 3.9c.6 1.5 1 3.1 1.1 4.6.1 1.6.1 2.9 0 4h-17.5m12.9-3v-1.1c0-.4 0-.8-.1-1.2-.1-.9-.4-1.7-.8-2.5s-1-1.5-1.8-2c-.9-.5-2-.8-3.4-.8-.8 0-1.5.1-2.3.3-.8.2-1.5.7-2.2 1.3-.7.6-1.2 1.3-1.6 2.3-.4 1-.7 2.2-.8 3.6h13zM765.3 29.5c0 .5.1 1 .2 1.4.1.5.4 1 .8 1.5s.9.8 1.6 1.1c.7.3 1.6.5 2.7.5 1 0 1.8-.1 2.5-.3.7-.2 1.3-.6 1.7-1.2.5-.7.8-1.5.8-2.4 0-1.2-.4-2-1.3-2.5s-2.2-.9-4.1-1.2c-1.3-.3-2.4-.6-3.6-1-1.1-.3-2.1-.8-3-1.3-.9-.5-1.5-1.2-2-2.1-.5-.8-.8-1.9-.8-3.2 0-2.4.9-4.2 2.6-5.6 1.7-1.3 4-2 6.8-2.1 1.6 0 3.3.3 5 .8 1.7.6 2.9 1.6 3.7 3.1.4 1.4.6 2.6.6 3.7h-4.6c0-1.8-.6-3-1.7-3.5-1.1-.4-2.1-.6-3.1-.6h-1c-.5 0-1.1.2-1.7.4-.6.2-1.1.5-1.5 1.1-.5.5-.7 1.2-.7 2.1 0 1.1.5 1.9 1.3 2.3.7.4 1.5.7 2.1.9 3.3.7 5.6 1.3 6.9 1.8 1.3.4 2.2 1 2.8 1.7.7.7 1.1 1.4 1.4 2.2.3.8.4 1.6.4 2.5 0 1.4-.3 2.7-.9 3.8-.6 1.1-1.4 2-2.4 2.6-1.1.6-2.2 1-3.4 1.3-1.2.3-2.5.4-3.8.4-2.5 0-4.7-.6-6.6-1.8-1.8-1.2-2.8-3.3-2.9-6.3h5.2zM467.7 50.8h21.9V55h-17.1v11.3h16.3v4.2h-16.3v12.1H490v4.3h-22.3zM499 64.7l-.1-2.9h4.6v4.1c.2-.3.4-.8.7-1.2.3-.5.8-1 1.3-1.5.6-.5 1.4-1 2.3-1.3.9-.3 2-.5 3.4-.5.6 0 1.4.1 2.4.2.9.2 1.9.5 2.9 1.1 1 .6 1.8 1.4 2.5 2.5.6 1.2 1 2.7 1 4.7V87h-4.6V71c0-.9-.1-1.7-.2-2.4-.2-.7-.5-1.3-1.1-1.9-1.2-1.1-2.6-1.7-4.3-1.7-1.7 0-3.1.6-4.3 1.8-1.3 1.2-2 3.1-2 5.7V87H499V64.7zM524.6 61.8h5.1l7.7 19.9 7.6-19.9h5l-10.6 25.1h-4.6zM555.7 50.9h5.5V56h-5.5v-5.1m.5 10.9h4.6v25.1h-4.6V61.8zM570.3 67c0-1.8-.1-3.5-.3-5.1h4.6l.1 4.9c.5-1.8 1.4-3 2.5-3.7 1.1-.7 2.2-1.2 3.3-1.3 1.4-.2 2.4-.2 3.1-.1v4.6c-.2-.1-.5-.2-.9-.2h-1.3c-1.3 0-2.4.2-3.3.5-.9.4-1.5.9-2 1.6-.9 1.4-1.4 3.2-1.3 5.4v13.3h-4.6V67zM587.6 74.7c0-1.6.2-3.2.6-4.8.4-1.6 1.1-3 2-4.4 1-1.3 2.2-2.4 3.8-3.2 1.6-.8 3.6-1.2 5.9-1.2 2.4 0 4.5.4 6.1 1.3 1.5.9 2.7 2 3.6 3.3.9 1.3 1.5 2.8 1.8 4.3.2.8.3 1.5.4 2.2v2.2c0 3.7-1 6.9-3 9.5-2 2.6-5.1 4-9.3 4-4-.1-7-1.4-9-3.9-1.9-2.5-2.9-5.6-2.9-9.3m4.8-.3c0 2.7.6 5 1.8 6.9 1.2 2 3 3 5.6 3.1.9 0 1.8-.2 2.7-.5.8-.3 1.6-.9 2.3-1.7.7-.8 1.3-1.9 1.8-3.2.4-1.3.6-2.9.6-4.7-.1-6.4-2.5-9.6-7.1-9.6-.7 0-1.5.1-2.4.3-.8.3-1.7.8-2.5 1.6-.8.7-1.4 1.7-1.9 3-.6 1.1-.9 2.8-.9 4.8zM620.2 64.7l-.1-2.9h4.6v4.1c.2-.3.4-.8.7-1.2.3-.5.8-1 1.3-1.5.6-.5 1.4-1 2.3-1.3.9-.3 2-.5 3.4-.5.6 0 1.4.1 2.4.2.9.2 1.9.5 2.9 1.1 1 .6 1.8 1.4 2.5 2.5.6 1.2 1 2.7 1 4.7V87h-4.6V71c0-.9-.1-1.7-.2-2.4-.2-.7-.5-1.3-1.1-1.9-1.2-1.1-2.6-1.7-4.3-1.7-1.7 0-3.1.6-4.3 1.8-1.3 1.2-2 3.1-2 5.7V87h-4.6V64.7zM650 65.1l-.1-3.3h4.6v3.6c1.2-1.9 2.6-3.2 4.1-3.7 1.5-.4 2.7-.6 3.8-.6 1.4 0 2.6.2 3.6.5.9.3 1.7.7 2.3 1.1 1.1 1 1.9 2 2.3 3.1.2-.4.5-.8 1-1.3.4-.5.9-1 1.5-1.6.6-.5 1.5-.9 2.5-1.3 1-.3 2.2-.5 3.5-.5.9 0 1.9.1 3 .3 1 .2 2 .7 3 1.3 1 .6 1.7 1.5 2.3 2.7.6 1.2.9 2.7.9 4.6v16.9h-4.6V70.7c0-1.1-.1-2-.2-2.5-.1-.6-.3-1-.6-1.3-.4-.6-1-1.2-1.8-1.6-.8-.4-1.8-.6-3.1-.6-1.5 0-2.7.4-3.6 1-.4.3-.8.5-1.1.9l-.8.8c-.5.8-.8 1.8-1 2.8-.1 1.1-.2 2-.1 2.6v14.1h-4.6V70.2c0-1.6-.5-2.9-1.4-4-.9-1-2.3-1.5-4.2-1.5-1.6 0-2.9.4-3.8 1.1-.9.7-1.5 1.2-1.8 1.7-.5.7-.8 1.5-.9 2.5-.1.9-.2 1.8-.2 2.6v14.3H650V65.1zM700.5 75.2c-.1 2.6.5 4.8 1.7 6.5 1.1 1.7 2.9 2.6 5.3 2.6 1.5 0 2.8-.4 3.9-1.3 1-.8 1.6-2.2 1.8-4h4.6c0 .6-.2 1.4-.4 2.3-.3 1-.8 2-1.7 3-.2.3-.6.6-1 1-.5.4-1 .7-1.7 1.1-.7.4-1.5.6-2.4.8-.9.3-2 .4-3.3.4-7.6-.2-11.3-4.5-11.3-12.9 0-2.5.3-4.8 1-6.8s2-3.7 3.8-5.1c1.2-.8 2.4-1.3 3.7-1.6 1.3-.2 2.2-.3 3-.3 2.7 0 4.8.6 6.3 1.6s2.5 2.3 3.1 3.9c.6 1.5 1 3.1 1.1 4.6.1 1.6.1 2.9 0 4h-17.5m12.8-3v-1.1c0-.4 0-.8-.1-1.2-.1-.9-.4-1.7-.8-2.5s-1-1.5-1.8-2c-.9-.5-2-.8-3.4-.8-.8 0-1.5.1-2.3.3-.8.2-1.5.7-2.2 1.3-.7.6-1.2 1.3-1.6 2.3-.4 1-.7 2.2-.8 3.6h13zM725.7 64.7l-.1-2.9h4.6v4.1c.2-.3.4-.8.7-1.2.3-.5.8-1 1.3-1.5.6-.5 1.4-1 2.3-1.3.9-.3 2-.5 3.4-.5.6 0 1.4.1 2.4.2.9.2 1.9.5 2.9 1.1 1 .6 1.8 1.4 2.5 2.5.6 1.2 1 2.7 1 4.7V87h-4.6V71c0-.9-.1-1.7-.2-2.4-.2-.7-.5-1.3-1.1-1.9-1.2-1.1-2.6-1.7-4.3-1.7-1.7 0-3.1.6-4.3 1.8-1.3 1.2-2 3.1-2 5.7V87h-4.6V64.7zM752.3 61.7h4.3v-5.2l4.5-1.5v6.8h5.4v3.4h-5.4v15.1c0 .3 0 .6.1 1 0 .4.1.7.4 1.1.2.4.5.6 1 .8.4.3 1 .4 1.8.4 1 0 1.7-.1 2.2-.2V87c-.9.2-2.1.3-3.8.3-2.1 0-3.6-.4-4.6-1.2-1-.8-1.5-2.2-1.5-4.2V65.1h-4.3v-3.4zM787.6 86.9c-.3-1.2-.5-2.5-.4-3.7-.5 1-1.1 1.8-1.7 2.4-.7.6-1.4 1.1-2 1.4-1.4.5-2.7.8-3.7.8-2.8 0-4.9-.8-6.4-2.2-1.5-1.4-2.2-3.1-2.2-5.2 0-1 .2-2.3.8-3.7.6-1.4 1.7-2.6 3.5-3.7 1.4-.7 2.9-1.2 4.5-1.5 1.6-.1 2.9-.2 3.9-.2s2.1 0 3.3.1c.1-2.9-.2-4.8-.9-5.6-.5-.6-1.1-1.1-1.9-1.3-.8-.2-1.6-.4-2.3-.4-1.1 0-2 .2-2.6.5-.7.3-1.2.7-1.5 1.2-.3.5-.5.9-.6 1.4-.1.5-.2.9-.2 1.2h-4.6c.1-.7.2-1.4.4-2.3.2-.8.6-1.6 1.3-2.5.5-.6 1-1 1.7-1.3.6-.3 1.3-.6 2-.8 1.5-.4 2.8-.6 4.2-.6 1.8 0 3.6.3 5.2.9 1.6.6 2.8 1.6 3.4 2.9.4.7.6 1.4.7 2 .1.6.1 1.2.1 1.8l-.2 12c0 1 .1 3.1.4 6.3h-4.2m-.5-12.1c-.7-.1-1.6-.1-2.6-.1h-2.1c-1 .1-2 .3-3 .6s-1.9.8-2.6 1.5c-.8.7-1.2 1.7-1.2 3 0 .4.1.8.2 1.3s.4 1 .8 1.5.9.8 1.6 1.1c.7.3 1.5.5 2.5.5 2.3 0 4.1-.9 5.2-2.7.5-.8.8-1.7 1-2.7.1-.9.2-2.2.2-4zM800.7 50.9h4.6V87h-4.6zM828.4 50.8h11.7c2.1 0 3.9.1 5.5.4.8.2 1.5.4 2.2.9.7.4 1.3.9 1.8 1.6 1.7 1.9 2.6 4.2 2.6 7 0 2.7-.9 5.1-2.8 7.1-.8.9-2 1.7-3.6 2.2-1.6.6-3.9.9-6.9.9h-5.7V87h-4.8V50.8m4.8 15.9h5.8c.8 0 1.7-.1 2.6-.2.9-.1 1.8-.3 2.6-.7.8-.4 1.5-1 2-1.9.5-.8.8-2 .8-3.4s-.2-2.5-.7-3.3c-.5-.8-1.1-1.3-1.9-1.7-1.6-.5-3.1-.8-4.5-.7h-6.8v11.9zM858.1 67c0-1.8-.1-3.5-.3-5.1h4.6l.1 4.9c.5-1.8 1.4-3 2.5-3.7 1.1-.7 2.2-1.2 3.3-1.3 1.4-.2 2.4-.2 3.1-.1v4.6c-.2-.1-.5-.2-.9-.2h-1.3c-1.3 0-2.4.2-3.3.5-.9.4-1.5.9-2 1.6-.9 1.4-1.4 3.2-1.3 5.4v13.3H858V67zM875.5 74.7c0-1.6.2-3.2.6-4.8.4-1.6 1.1-3 2-4.4 1-1.3 2.2-2.4 3.8-3.2 1.6-.8 3.6-1.2 5.9-1.2 2.4 0 4.5.4 6.1 1.3 1.5.9 2.7 2 3.6 3.3.9 1.3 1.5 2.8 1.8 4.3.2.8.3 1.5.4 2.2v2.2c0 3.7-1 6.9-3 9.5-2 2.6-5.1 4-9.3 4-4-.1-7-1.4-9-3.9-1.9-2.5-2.9-5.6-2.9-9.3m4.8-.3c0 2.7.6 5 1.8 6.9 1.2 2 3 3 5.6 3.1.9 0 1.8-.2 2.7-.5.8-.3 1.6-.9 2.3-1.7.7-.8 1.3-1.9 1.8-3.2.4-1.3.6-2.9.6-4.7-.1-6.4-2.5-9.6-7.1-9.6-.7 0-1.5.1-2.4.3-.8.3-1.7.8-2.5 1.6-.8.7-1.4 1.7-1.9 3-.7 1.1-.9 2.8-.9 4.8zM904.1 61.7h4.3v-5.2l4.5-1.5v6.8h5.4v3.4h-5.4v15.1c0 .3 0 .6.1 1 0 .4.1.7.4 1.1.2.4.5.6 1 .8.4.3 1 .4 1.8.4 1 0 1.7-.1 2.2-.2V87c-.9.2-2.1.3-3.8.3-2.1 0-3.6-.4-4.6-1.2-1-.8-1.5-2.2-1.5-4.2V65.1h-4.3v-3.4zM927.2 75.2c-.1 2.6.5 4.8 1.7 6.5 1.1 1.7 2.9 2.6 5.3 2.6 1.5 0 2.8-.4 3.9-1.3 1-.8 1.6-2.2 1.8-4h4.6c0 .6-.2 1.4-.4 2.3-.3 1-.8 2-1.7 3-.2.3-.6.6-1 1-.5.4-1 .7-1.7 1.1-.7.4-1.5.6-2.4.8-.9.3-2 .4-3.3.4-7.6-.2-11.3-4.5-11.3-12.9 0-2.5.3-4.8 1-6.8s2-3.7 3.8-5.1c1.2-.8 2.4-1.3 3.7-1.6 1.3-.2 2.2-.3 3-.3 2.7 0 4.8.6 6.3 1.6s2.5 2.3 3.1 3.9c.6 1.5 1 3.1 1.1 4.6.1 1.6.1 2.9 0 4h-17.5m12.9-3v-1.1c0-.4 0-.8-.1-1.2-.1-.9-.4-1.7-.8-2.5s-1-1.5-1.8-2c-.9-.5-2-.8-3.4-.8-.8 0-1.5.1-2.3.3-.8.2-1.5.7-2.2 1.3-.7.6-1.2 1.3-1.6 2.3-.4 1-.7 2.2-.8 3.6h13zM966.1 69.8c0-.3 0-.8-.1-1.4-.1-.6-.3-1.1-.6-1.8-.2-.6-.7-1.2-1.4-1.6-.7-.4-1.6-.6-2.7-.6-1.5 0-2.7.4-3.5 1.2-.9.8-1.5 1.7-1.9 2.8-.4 1.1-.6 2.2-.7 3.2-.1 1.1-.2 1.8-.1 2.4 0 1.3.1 2.5.3 3.7.2 1.2.5 2.3.9 3.3.8 2 2.4 3 4.8 3.1 1.9 0 3.3-.7 4.1-1.9.8-1.1 1.2-2.3 1.2-3.6h4.6c-.2 2.5-1.1 4.6-2.7 6.3-1.7 1.8-4.1 2.7-7.1 2.7-.9 0-2.1-.2-3.6-.6-.7-.2-1.4-.6-2.2-1-.8-.4-1.5-1-2.2-1.7-.7-.9-1.4-2.1-2-3.6-.6-1.5-.9-3.5-.9-6.1 0-2.6.4-4.8 1.1-6.6.7-1.7 1.6-3.1 2.7-4.2 1.1-1 2.3-1.8 3.6-2.2 1.3-.4 2.5-.6 3.7-.6h1.6c.6.1 1.3.2 1.9.4.7.2 1.4.5 2.1 1 .7.4 1.3 1 1.8 1.7.9 1.1 1.4 2.1 1.7 3.1.2 1 .3 1.8.3 2.6h-4.7zM973.6 61.7h4.3v-5.2l4.5-1.5v6.8h5.4v3.4h-5.4v15.1c0 .3 0 .6.1 1 0 .4.1.7.4 1.1.2.4.5.6 1 .8.4.3 1 .4 1.8.4 1 0 1.7-.1 2.2-.2V87c-.9.2-2.1.3-3.8.3-2.1 0-3.6-.4-4.6-1.2-1-.8-1.5-2.2-1.5-4.2V65.1h-4.3v-3.4zM993.5 50.9h5.5V56h-5.5v-5.1m.5 10.9h4.6v25.1H994V61.8zM1006.1 74.7c0-1.6.2-3.2.6-4.8.4-1.6 1.1-3 2-4.4 1-1.3 2.2-2.4 3.8-3.2 1.6-.8 3.6-1.2 5.9-1.2 2.4 0 4.5.4 6.1 1.3 1.5.9 2.7 2 3.6 3.3.9 1.3 1.5 2.8 1.8 4.3.2.8.3 1.5.4 2.2v2.2c0 3.7-1 6.9-3 9.5-2 2.6-5.1 4-9.3 4-4-.1-7-1.4-9-3.9-1.9-2.5-2.9-5.6-2.9-9.3m4.7-.3c0 2.7.6 5 1.8 6.9 1.2 2 3 3 5.6 3.1.9 0 1.8-.2 2.7-.5.8-.3 1.6-.9 2.3-1.7.7-.8 1.3-1.9 1.8-3.2.4-1.3.6-2.9.6-4.7-.1-6.4-2.5-9.6-7.1-9.6-.7 0-1.5.1-2.4.3-.8.3-1.7.8-2.5 1.6-.8.7-1.4 1.7-1.9 3-.6 1.1-.9 2.8-.9 4.8zM1038.6 64.7l-.1-2.9h4.6v4.1c.2-.3.4-.8.7-1.2.3-.5.8-1 1.3-1.5.6-.5 1.4-1 2.3-1.3.9-.3 2-.5 3.4-.5.6 0 1.4.1 2.4.2.9.2 1.9.5 2.9 1.1 1 .6 1.8 1.4 2.5 2.5.6 1.2 1 2.7 1 4.7V87h-4.6V71c0-.9-.1-1.7-.2-2.4-.2-.7-.5-1.3-1.1-1.9-1.2-1.1-2.6-1.7-4.3-1.7-1.7 0-3.1.6-4.3 1.8-1.3 1.2-2 3.1-2 5.7V87h-4.6V64.7zM479.1 100.8h5.2l14.1 36.1h-5.3l-3.8-9.4h-16.2l-3.8 9.4h-5l14.8-36.1m-4.4 22.7H488l-6.5-17.8-6.8 17.8zM508.7 138.8c.1.7.2 1.4.4 1.9.2.6.5 1.1.9 1.6.8.9 2.3 1.4 4.4 1.5 1.6 0 2.8-.3 3.7-.9.9-.6 1.5-1.4 1.9-2.4.4-1.1.6-2.3.7-3.7.1-1.4.1-2.9.1-4.6-.5.9-1.1 1.7-1.8 2.3-.7.6-1.5 1-2.3 1.3-1.7.4-3 .6-3.9.6-1.2 0-2.4-.2-3.8-.6-1.4-.4-2.6-1.2-3.7-2.5-1-1.3-1.7-2.8-2.1-4.4-.4-1.6-.6-3.2-.6-4.8 0-4.3 1.1-7.4 3.2-9.5 2-2.1 4.6-3.1 7.6-3.1 1.3 0 2.3.1 3.2.4.9.3 1.6.6 2.1 1 .6.4 1.1.8 1.5 1.2l.9 1.2v-3.4h4.4l-.1 4.5v15.7c0 2.9-.1 5.2-.2 6.7-.2 1.6-.5 2.8-1 3.7-1.1 1.9-2.6 3.2-4.6 3.7-1.9.6-3.8.8-5.6.8-2.4 0-4.3-.3-5.6-.8-1.4-.5-2.4-1.2-3-2-.6-.8-1-1.7-1.2-2.7-.2-.9-.3-1.8-.4-2.7h4.9m5.3-5.8c1.4 0 2.5-.2 3.3-.7.8-.5 1.5-1.1 2-1.8.5-.6.9-1.4 1.2-2.5.3-1 .4-2.6.4-4.8 0-1.6-.2-2.9-.4-3.9-.3-1-.8-1.8-1.4-2.4-1.3-1.4-3-2.2-5.2-2.2-1.4 0-2.5.3-3.4 1-.9.7-1.6 1.5-2 2.4-.4 1-.7 2-.9 3-.2 1-.2 2-.2 2.8 0 1 .1 1.9.3 2.9.2 1.1.5 2.1 1 3 .5.9 1.2 1.6 2 2.2.8.7 1.9 1 3.3 1zM537.6 125.2c-.1 2.6.5 4.8 1.7 6.5 1.1 1.7 2.9 2.6 5.3 2.6 1.5 0 2.8-.4 3.9-1.3 1-.8 1.6-2.2 1.8-4h4.6c0 .6-.2 1.4-.4 2.3-.3 1-.8 2-1.7 3-.2.3-.6.6-1 1-.5.4-1 .7-1.7 1.1-.7.4-1.5.6-2.4.8-.9.3-2 .4-3.3.4-7.6-.2-11.3-4.5-11.3-12.9 0-2.5.3-4.8 1-6.8s2-3.7 3.8-5.1c1.2-.8 2.4-1.3 3.7-1.6 1.3-.2 2.2-.3 3-.3 2.7 0 4.8.6 6.3 1.6s2.5 2.3 3.1 3.9c.6 1.5 1 3.1 1.1 4.6.1 1.6.1 2.9 0 4h-17.5m12.9-3v-1.1c0-.4 0-.8-.1-1.2-.1-.9-.4-1.7-.8-2.5s-1-1.5-1.8-2.1c-.9-.5-2-.8-3.4-.8-.8 0-1.5.1-2.3.3-.8.2-1.5.7-2.2 1.3-.7.6-1.2 1.3-1.6 2.3-.4 1-.7 2.2-.8 3.7h13zM562.9 114.7l-.1-2.9h4.6v4.1c.2-.3.4-.8.7-1.2.3-.5.8-1 1.3-1.5.6-.5 1.4-1 2.3-1.3.9-.3 2-.5 3.4-.5.6 0 1.4.1 2.4.2.9.2 1.9.5 2.9 1.1 1 .6 1.8 1.4 2.5 2.5.6 1.2 1 2.7 1 4.7V137h-4.6v-16c0-.9-.1-1.7-.2-2.4-.2-.7-.5-1.3-1.1-1.9-1.2-1.1-2.6-1.7-4.3-1.7-1.7 0-3.1.6-4.3 1.8-1.3 1.2-2 3.1-2 5.7V137h-4.6v-22.3zM607 119.8c0-.3 0-.8-.1-1.4-.1-.6-.3-1.1-.6-1.8-.2-.6-.7-1.2-1.4-1.6-.7-.4-1.6-.6-2.7-.6-1.5 0-2.7.4-3.5 1.2-.9.8-1.5 1.7-1.9 2.8-.4 1.1-.6 2.2-.7 3.2-.1 1.1-.2 1.8-.1 2.4 0 1.3.1 2.5.3 3.7.2 1.2.5 2.3.9 3.3.8 2 2.4 3 4.8 3.1 1.9 0 3.3-.7 4.1-1.9.8-1.1 1.2-2.3 1.2-3.6h4.6c-.2 2.5-1.1 4.6-2.7 6.3-1.7 1.8-4.1 2.7-7.1 2.7-.9 0-2.1-.2-3.6-.6-.7-.2-1.4-.6-2.2-1-.8-.4-1.5-1-2.2-1.7-.7-.9-1.4-2.1-2-3.6-.6-1.5-.9-3.5-.9-6.1 0-2.6.4-4.8 1.1-6.6.7-1.7 1.6-3.1 2.7-4.2 1.1-1 2.3-1.8 3.6-2.2 1.3-.4 2.5-.6 3.7-.6h1.6c.6.1 1.3.2 1.9.4.7.2 1.4.5 2.1 1 .7.4 1.3 1 1.8 1.7.9 1.1 1.4 2.1 1.7 3.1.2 1 .3 1.8.3 2.6H607zM629.1 137.1l-3.4 9.3H621l3.8-9.6-10.3-25h5.2l7.6 19.8 7.7-19.8h5z"/>
	</svg>
	</span>
	</a>
	<button class="usa-menu-btn usa-button l-header__menu-button">Menu</button>
	</div>
	<div class="l-header__search">
	<form class="usa-search usa-search--small usa-search--epa" method="get" action="https://search.epa.gov/epasearch">
	<div role="search">
	<label class="usa-sr-only" for="search-box">Search</label>
	<input class="usa-input" id="search-box" type="search" name="querytext" placeholder="Search EPA.gov">
	<!-- button class="usa-button" type="submit" --> <!-- type="submit" - removed for now to allow other unrendered buttons to render when triggered in RShiny app -->
	<!-- see: https://github.com/rstudio/shiny/issues/2922 -->
	<button class="usa-button usa-search__submit" style="height:2rem;margin:0;padding:0;padding-left:1rem;padding-right:1rem;border-top-left-radius: 0;border-bottom-left-radius: 0;">
	<span class="usa-sr-only">Search</span>
	</button>
	<input type="hidden" name="areaname" value="">
	<input type="hidden" name="areacontacts" value="">
	<input type="hidden" name="areasearchurl" value="">
	<input type="hidden" name="typeofsearch" value="epa">
	<input type="hidden" name="result_template" value="">
	</div>
	</form>
	</div>
	</div>
	</div>
	<div class="l-header__nav">
	<nav class="usa-nav usa-nav--epa" role="navigation" aria-label="EPA header navigation">
	<div class="usa-nav__inner">
	<button class="usa-nav__close" aria-label="Close">
	<svg class="icon icon--nav-close" aria-hidden="true" role="img">
	<title>Primary navigation</title>
	<use xlink:href="https://www.epa.gov/themes/epa_theme/images/sprite.artifact.svg#close"></use>
	</svg> </button>
	<div class="usa-nav__menu">
	<ul class="menu menu--main">
	<li class="menu__item"><a href="https://www.epa.gov/environmental-topics" class="menu__link">Environmental Topics</a></li>
	<li class="menu__item"><a href="https://www.epa.gov/laws-regulations" class="menu__link" >Laws &amp; Regulations</a></li>
	<li class="menu__item"><a href="https://www.epa.gov/report-violation" class="menu__link" >Report a Violation</a></li>
	<li class="menu__item"><a href="https://www.epa.gov/aboutepa" class="menu__link" >About EPA</a></li>
	</ul>
	</div>
	</div>
	</nav>
	</div>
	</header>
	<main id="main" class="main" role="main" tabindex="-1">'
	),
	
	# Individual Page Header
	HTML(
		'<div class="l-page  has-footer">
		<div class="l-constrain">
		<div class="l-page__header">
		<div class="l-page__header-first">
		<div class="web-area-title"></div>
		</div>
		<div class="l-page__header-last">
		<a href="#" class="header-link">Contact Us</a>
		</div>
		</div>
		<article class="article">'
		),
	
# Insert your UI code here
			  
		navbarPage	(
					"Dashboard",
					id="tabs",
					selected="Overall & Subpopulation Results",
					header = tagList(
									useShinydashboard(),
									shinyjs::useShinyjs()
									),
					theme = bslib::bs_theme(bootswatch = "minty"),
					tabPanel(
							title="About",
							fluidRow(
									box	(width=11,
										solidHeader = TRUE,
										title="About this Dashboard",
										status="primary",
										htmlOutput("about_text")
										)
									)
							),
					# Tab for the Overall & Subpopulation Results
					tabPanel(
							title="Overall & Subpopulation Results",
							fluidRow	(
										column(
												width=2,
												box(
													width=15, 
													title="Options", 
													solidHeader = TRUE,
													status="primary",
													htmlOutput("overall_info_text"),
													radioButtons(
																"subpop", 
																tags$span(style = "font-weight: bold;", "Subpopulation:"),
																c(
																	"All" = "All",
																	"Age" = "Age",
																	"Sex" = "Sex",
																	"Race" = "Race",
																	"Diabetes" = "Diabetes",
																	"Chronic Kidney Disease (CKD)" = "CKD"
																 )
																),
													radioButtons(
																"sub", 
																tags$span	(
																			style = "font-weight: bold;",
																			"Stratification:"
																			),
																c(
																"Overall" = "Primary",
																"Urban Heat Island Intensity (UHII)" = "UHII"
																)
															   ),
													radioButtons(
																"type", 
																tags$span(
																			style = "font-weight: bold;", 
																			"Plot Type:"
																		 ),
																c(
																"Cumulative (Lags 0-21)" = "pooled",
																"Lags at 99th %ile" = "lags"
																)
																)
												   )
											  ),
										box	(
											width=5, 
											title="Exposure-Lag-Response Curves",
											solidHeader = TRUE,
											status="primary",
											plotOutput("pooled_curve")  %>% withSpinner(color="#a9a9a9"),
											div(htmlOutput("pooled_curve_text"),style="font-size:90%")
											),
										box	(
											width=5,
											title="Primary Results",
											solidHeader=TRUE,
											status="primary",
											align='right',
											radioButtons	(
															"bar.var",
															NULL,
															c("AN","AR"),
															inline=T
															),
											plotlyOutput("pooled_plots")  %>% withSpinner(color="#a9a9a9"),
											div(htmlOutput("pooled_plot_text"),style="font-size:90%",align='left')
											)
										),
							fluidRow	(
										box	(
											width=2, 
											title="Key Takeaways", 
											solidHeader = TRUE,
											status="primary",
											tags$style(HTML("ul { list-style-position: outside; padding-left: 1em;} ")),
											htmlOutput("main_takeaway") %>% withSpinner(color="#a9a9a9")
											),
										box	(
											width=10,
											title="Table of Results",
											solidHeader=TRUE,
											status="primary",
											div(DT::dataTableOutput("pooled_table")  %>% withSpinner(color="#a9a9a9"),style = "font-size:80%"),
											tags$style(type="text/css", "#downloadAllData {background-color:#F8F8F8;border-color:#dbd9d9;color: black}"),
											downloadButton("downloadAllData", "Download all results")
											)
										)
							),
					# Tab for the MSA-Specific Results
					tabPanel(title="MSA-Specific Results",
					fluidRow(
					column(width=2,
					box(width=15, title="Options", solidHeader = TRUE,status="primary",
					htmlOutput("cbsa_info_text"),
					radioButtons("forest_variable", tags$span(style = "font-weight: bold;", "Variable:"),
								c("RR (99th vs. MHP)" = "rr.99",
								  "Heat AN (Temp. >= MHP)" = "an.heat",
								  "Heat AF (%)" = "af.heat",
								  "Heat AR (per 100k)" = "ar.heat",
								  "MHT (\u00b0C)" = "mht"
								)),
					radioButtons("forest_type", tags$span(style = "font-weight: bold;", "Stratification:"),
								c("Overall" = "Primary",
								  "Urban Heat Island Intensity (UHII)" = "UHII"
								)),
					radioButtons("forest_color",tags$span(style = "font-weight: bold;", "Color by MSA Characteristic:"),
								c("None" = "none",
								  "Avg. Temperature" = "avg.temp",
								  "Avg. Temperature Range" = "avg.range",
								  "Region" = "region",
								  "Climate Type" = "climate")),
					checkboxInput("sort", "Sort by MSA Characteristic",
								 value=FALSE)
					),
					box(width=15, title="Key Takeaways", solidHeader = TRUE,status="primary",
					tags$style(HTML("ul { list-style-position: outside; padding-left: 1em;} ")),
					htmlOutput("msa_takeaway")%>% withSpinner(color="#a9a9a9")
					)
					),
					tabBox(width=6,title="",id="cbsa_tabs",
					tabPanel("Forest/Bar Plot",
						tags$style(tabbox.style),
						tags$style(type = "text/css", "#forest_plot {height: calc(100vh + 1000px) !important;}"),
						plotlyOutput('forest_plot') %>% withSpinner(color="#a9a9a9")
					),
					tabPanel("Interactive Map",
						tags$style(type = "text/css", "#cbsa_map {height: calc(100vh - 180px) !important;}",
								   ".shiny-output-error { visibility: hidden; }",
								   ".shiny-output-error:before { visibility: hidden; }"),
						leafletOutput("cbsa_map")  %>% withSpinner(color="#a9a9a9")
					)

					),

					box(width=4,title="MSA-Specific Results",solidHeader = TRUE,status="primary",
					selectInput(inputId="cbsa_choice",
						label="Select an MSA (below or in the forest/bar plot or map to the left):",
						choices = unique(cbsa_all$CBSA.Title)),
					htmlOutput("cbsa_title"),
					plotOutput("cbsa_curve",height=300)  %>% withSpinner(color="#a9a9a9"),
					DT::dataTableOutput("cbsa_table")  %>% withSpinner(color="#a9a9a9"),
					tags$style(type="text/css", "#downloadMSAData {background-color:#F8F8F8;border-color:#dbd9d9;color: black}"),
					downloadButton("downloadMSAData", "Download results for all MSAs")
					)
					)
					),
					# Tab for the Exposure & Outcome Maps
					tabPanel(title="Exposure & Outcome Maps",
					fluidRow(tags$style(HTML(box.style)),
					box(width=2, title="Options", solidHeader = TRUE,status="primary",
					htmlOutput("map_info_text"),
					radioButtons("variable", tags$span(style = "font-weight: bold;", "Variable:"),
								c("Avg. Temperature" = "temp",
								  "Avg. Temperature Range" = "range",
								  "99th Temperature Percentile"="temp.99",
								  "# Hospitalizations" = "hosp",
								  "Urban Heat Island Intensity (UHII)" = "uhi",
								  "UHII Quartile" = "uhiq"
								)),
					tags$head(tags$script(HTML("
					$(document).ready(function(e) {
					  $('input[value=\"temp\"]').parent().parent().before('<i><u>Exposure</u><i>');
					})
					"))),
					tags$head(tags$script(HTML("
					$(document).ready(function(e) {
					  $('input[value=\"temp.99\"]').parent().parent().after('<br><i><u>Outcome</u><i>');
					})
					"))),
					tags$head(tags$script(HTML("
					$(document).ready(function(e) {
					  $('input[value=\"hosp\"]').parent().parent().after('<br><i><u>UHI</u><i>');
					})
					")))

					),
					box(width=10,title="Interactive Map", solidHeader = TRUE,status="primary",
					tags$style(type = "text/css", "#leaflet_map {height: calc(100vh - 180px) !important;}"),
					leafletOutput("leaflet_map")  %>% withSpinner(color="#a9a9a9"),
					htmlOutput("leaflet_text")
					)
					)
					),
					inverse=F
					)

# IMPORTANT! For a navbar page, you will need to place the header and footer inside the navbar section (as shown below)  -
# you will then want to comment out lines 201-213 and lines 254-263
#   navbarPage(
#     title = h2("Sample App"),
#     header = HTML(
#       '<div class="l-page  has-footer">
#         <div class="l-constrain">
#           <div class="l-page__header">
#             <div class="l-page__header-first">
#               <div class="web-area-title"></div>
#             </div>
#             <div class="l-page__header-last">
#               <a href="#" class="header-link">Contact Us</a>
#             </div>
#           </div>
#           <article class="article">'
#     ),
#     footer = HTML(
#       '</article>
# 	        </div>
#           <div class="l-page__footer">
#             <div class="l-constrain">
#               <p><a href="#">Contact Us</a> to ask a question, provide feedback, or report a problem.</p>
#             </div>
#           </div>
#         </div>'
#     ),
#     tabPanel("Sample Tab 1"),
#     tabPanel("Sample Tab 2"),
#   ),

# Individual Page Footer
,HTML(
'</article>
</div>
<div class="l-page__footer">
<div class="l-constrain">
<p><a href="#">Contact Us</a> to ask a question, provide feedback, or report a problem.</p>
</div>
</div>
</div>'
),

# Site Footer
HTML(
'</main>
<footer class="footer" role="contentinfo">
<div class="l-constrain">
<img class="footer__epa-seal" src="https://www.epa.gov/themes/epa_theme/images/epa-seal.svg" alt="United States Environmental Protection Agency" height="100" width="100">
<div class="footer__content contextual-region">
<div class="footer__column">
<h2>Discover.</h2>
<ul class="menu menu--footer">
<li class="menu__item">
<a href="https://www.epa.gov/accessibility" class="menu__link">Accessibility</a>
</li>
<!--li class="menu__item"><a href="#" class="menu__link">EPA Administrator</a></li-->
<li class="menu__item">
<a href="https://www.epa.gov/planandbudget" class="menu__link">Budget &amp; Performance</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/contracts" class="menu__link">Contracting</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/home/wwwepagov-snapshots" class="menu__link">EPA www Web Snapshot</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/grants" class="menu__link">Grants</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/ocr/whistleblower-protections-epa-and-how-they-relate-non-disclosure-agreements-signed-epa-employees" class="menu__link">No FEAR Act Data</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/web-policies-and-procedures/plain-writing" class="menu__link">Plain Writing</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/privacy" class="menu__link">Privacy</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/privacy/privacy-and-security-notice" class="menu__link">Privacy and Security Notice</a>
</li>
</ul>
</div>
<div class="footer__column">
<h2>Connect.</h2>
<ul class="menu menu--footer">
<li class="menu__item">
<a href="https://www.data.gov/" class="menu__link">Data.gov</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/office-inspector-general/about-epas-office-inspector-general" class="menu__link">Inspector General</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/careers" class="menu__link">Jobs</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/newsroom" class="menu__link">Newsroom</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/data" class="menu__link">Open Government</a>
</li>
<li class="menu__item">
<a href="https://www.regulations.gov/" class="menu__link">Regulations.gov</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/newsroom/email-subscriptions-epa-news-releases" class="menu__link">Subscribe</a>
</li>
<li class="menu__item">
<a href="https://www.usa.gov/" class="menu__link">USA.gov</a>
</li>
<li class="menu__item">
<a href="https://www.whitehouse.gov/" class="menu__link">White House</a>
</li>
</ul>
</div>
<div class="footer__column">
<h2>Ask.</h2>
<ul class="menu menu--footer">
<li class="menu__item">
<a href="https://www.epa.gov/home/forms/contact-epa" class="menu__link">Contact EPA</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/web-policies-and-procedures/epa-disclaimers" class="menu__link">EPA Disclaimers</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/aboutepa/epa-hotlines" class="menu__link">Hotlines</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/foia" class="menu__link">FOIA Requests</a>
</li>
<li class="menu__item">
<a href="https://www.epa.gov/home/frequent-questions-specific-epa-programstopics" class="menu__link">Frequent Questions</a>
</li>
</ul>
<h2>Follow.</h2>
<ul class="menu menu--social">
<li class="menu__item">
<a class="menu__link" aria-label="EPA’s Facebook" href="https://www.facebook.com/EPA">
<!-- svg class="icon icon--social" aria-hidden="true" -->
<svg class="icon icon--social" aria-hidden="true" viewBox="0 0 448 512" id="facebook-square" xmlns="http://www.w3.org/2000/svg">
<!-- use xlink:href="https://www.epa.gov/themes/epa_theme/images/sprite.artifact.svg#facebook-square"></use-->
<path fill="currentcolor" d="M400 32H48A48 48 0 000 80v352a48 48 0 0048 48h137.25V327.69h-63V256h63v-54.64c0-62.15 37-96.48 93.67-96.48 27.14 0 55.52 4.84 55.52 4.84v61h-31.27c-30.81 0-40.42 19.12-40.42 38.73V256h68.78l-11 71.69h-57.78V480H400a48 48 0 0048-48V80a48 48 0 00-48-48z"></path>
</svg> 
<span class="usa-tag external-link__tag" title="Exit EPA Website">
<span aria-hidden="true">Exit</span>
<span class="u-visually-hidden"> Exit EPA Website</span>
</span>
</a>
</li>
<li class="menu__item">
<a class="menu__link" aria-label="EPA’s Twitter" href="https://twitter.com/epa">
<!-- svg class="icon icon--social" aria-hidden="true" -->
<svg class="icon icon--social" aria-hidden="true" viewBox="0 0 448 512" id="twitter-square" xmlns="http://www.w3.org/2000/svg">
<!-- use xlink:href="https://www.epa.gov/themes/epa_theme/images/sprite.artifact.svg#twitter-square"></use -->
<path fill="currentcolor" d="M400 32H48C21.5 32 0 53.5 0 80v352c0 26.5 21.5 48 48 48h352c26.5 0 48-21.5 48-48V80c0-26.5-21.5-48-48-48zm-48.9 158.8c.2 2.8.2 5.7.2 8.5 0 86.7-66 186.6-186.6 186.6-37.2 0-71.7-10.8-100.7-29.4 5.3.6 10.4.8 15.8.8 30.7 0 58.9-10.4 81.4-28-28.8-.6-53-19.5-61.3-45.5 10.1 1.5 19.2 1.5 29.6-1.2-30-6.1-52.5-32.5-52.5-64.4v-.8c8.7 4.9 18.9 7.9 29.6 8.3a65.447 65.447 0 01-29.2-54.6c0-12.2 3.2-23.4 8.9-33.1 32.3 39.8 80.8 65.8 135.2 68.6-9.3-44.5 24-80.6 64-80.6 18.9 0 35.9 7.9 47.9 20.7 14.8-2.8 29-8.3 41.6-15.8-4.9 15.2-15.2 28-28.8 36.1 13.2-1.4 26-5.1 37.8-10.2-8.9 13.1-20.1 24.7-32.9 34z"></path>
</svg>
<span class="usa-tag external-link__tag" title="Exit EPA Website">
<span aria-hidden="true">Exit</span>
<span class="u-visually-hidden"> Exit EPA Website</span>
</span>
</a>
</li>
<li class="menu__item">
<a class="menu__link" aria-label="EPA’s Youtube" href="https://www.youtube.com/user/USEPAgov">
<!-- svg class="icon icon--social" aria-hidden="true" -->
<svg class="icon icon--social" aria-hidden="true" viewBox="0 0 448 512" id="youtube-square" xmlns="http://www.w3.org/2000/svg">
<!-- use xlink:href="https://www.epa.gov/themes/epa_theme/images/sprite.artifact.svg#youtube-square"></use -->
<path fill="currentcolor" d="M186.8 202.1l95.2 54.1-95.2 54.1V202.1zM448 80v352c0 26.5-21.5 48-48 48H48c-26.5 0-48-21.5-48-48V80c0-26.5 21.5-48 48-48h352c26.5 0 48 21.5 48 48zm-42 176.3s0-59.6-7.6-88.2c-4.2-15.8-16.5-28.2-32.2-32.4C337.9 128 224 128 224 128s-113.9 0-142.2 7.7c-15.7 4.2-28 16.6-32.2 32.4-7.6 28.5-7.6 88.2-7.6 88.2s0 59.6 7.6 88.2c4.2 15.8 16.5 27.7 32.2 31.9C110.1 384 224 384 224 384s113.9 0 142.2-7.7c15.7-4.2 28-16.1 32.2-31.9 7.6-28.5 7.6-88.1 7.6-88.1z"></path>
</svg>
<span class="usa-tag external-link__tag" title="Exit EPA Website">
<span aria-hidden="true">Exit</span>
<span class="u-visually-hidden"> Exit EPA Website</span>
</span>
</a>
</li>
<li class="menu__item">
<a class="menu__link" aria-label="EPA’s Flickr" href="https://www.flickr.com/photos/usepagov">
<!-- svg class="icon icon--social" aria-hidden="true" -->
<svg class="icon icon--social" aria-hidden="true" viewBox="0 0 448 512" id="flickr-square" xmlns="http://www.w3.org/2000/svg">
<!-- use xlink:href="https://www.epa.gov/themes/epa_theme/images/sprite.artifact.svg#flickr-square"></use -->
<path fill="currentcolor" d="M400 32H48C21.5 32 0 53.5 0 80v352c0 26.5 21.5 48 48 48h352c26.5 0 48-21.5 48-48V80c0-26.5-21.5-48-48-48zM144.5 319c-35.1 0-63.5-28.4-63.5-63.5s28.4-63.5 63.5-63.5 63.5 28.4 63.5 63.5-28.4 63.5-63.5 63.5zm159 0c-35.1 0-63.5-28.4-63.5-63.5s28.4-63.5 63.5-63.5 63.5 28.4 63.5 63.5-28.4 63.5-63.5 63.5z"></path>
</svg>
<span class="usa-tag external-link__tag" title="Exit EPA Website">
<span aria-hidden="true">Exit</span>
<span class="u-visually-hidden"> Exit EPA Website</span>
</span>
</a>
</li>
<li class="menu__item">
<a class="menu__link" aria-label="EPA’s Instagram" href="https://www.instagram.com/epagov">
<!-- svg class="icon icon--social" aria-hidden="true" -->
<svg class="icon icon--social" aria-hidden="true" viewBox="0 0 448 512" id="instagram-square" xmlns="http://www.w3.org/2000/svg">
<!-- use xlink:href="https://www.epa.gov/themes/epa_theme/images/sprite.artifact.svg#instagram-square"></use -->
<path fill="currentcolor" xmlns="http://www.w3.org/2000/svg" d="M224 202.66A53.34 53.34 0 10277.36 256 53.38 53.38 0 00224 202.66zm124.71-41a54 54 0 00-30.41-30.41c-21-8.29-71-6.43-94.3-6.43s-73.25-1.93-94.31 6.43a54 54 0 00-30.41 30.41c-8.28 21-6.43 71.05-6.43 94.33s-1.85 73.27 6.47 94.34a54 54 0 0030.41 30.41c21 8.29 71 6.43 94.31 6.43s73.24 1.93 94.3-6.43a54 54 0 0030.41-30.41c8.35-21 6.43-71.05 6.43-94.33s1.92-73.26-6.43-94.33zM224 338a82 82 0 1182-82 81.9 81.9 0 01-82 82zm85.38-148.3a19.14 19.14 0 1119.13-19.14 19.1 19.1 0 01-19.09 19.18zM400 32H48A48 48 0 000 80v352a48 48 0 0048 48h352a48 48 0 0048-48V80a48 48 0 00-48-48zm-17.12 290c-1.29 25.63-7.14 48.34-25.85 67s-41.4 24.63-67 25.85c-26.41 1.49-105.59 1.49-132 0-25.63-1.29-48.26-7.15-67-25.85s-24.63-41.42-25.85-67c-1.49-26.42-1.49-105.61 0-132 1.29-25.63 7.07-48.34 25.85-67s41.47-24.56 67-25.78c26.41-1.49 105.59-1.49 132 0 25.63 1.29 48.33 7.15 67 25.85s24.63 41.42 25.85 67.05c1.49 26.32 1.49 105.44 0 131.88z"></path>
</svg>
<span class="usa-tag external-link__tag" title="Exit EPA Website">
<span aria-hidden="true">Exit</span>
<span class="u-visually-hidden"> Exit EPA Website</span>
</span>
</a>
</li>
</ul>
<p class="footer__last-updated">
Last updated on March 30, 2022
</p>
</div>
</div>
</div>
</footer>
<a href="#" class="back-to-top" title="">
<svg class="back-to-top__icon" role="img" aria-label="">
<svg class="back-to-top__icon" role="img" aria-label="" viewBox="0 0 19 12" id="arrow" xmlns="http://www.w3.org/2000/svg">
<!-- use xlink:href="https://www.epa.gov/themes/epa_theme/images/sprite.artifact.svg#arrow"></use -->
<path fill="currentColor" d="M2.3 12l7.5-7.5 7.5 7.5 2.3-2.3L9.9 0 .2 9.7 2.5 12z"></path>
</svg>
</a>'
)
) # END fluidPage

# Insert your server code here
server <- function(input, output,session) { 

# Observe event used to generate leaflet maps
observe({

# Maps for the Exposure & Outcome Maps tab
if (input$tabs == "Exposure & Outcome Maps") { 
if (input$variable=="uhi") {
var = "UHI_summer_day.Wght"; title = "UHII (\u00b0C)"
rev=F
} else if (input$variable=="hosp") {
var="n.HAs"; title = "# Hospitalizations"
bins = c(0,1500,3000,4500,6000,7500,9000,10500,12000,70000)
labs = c("0-1,500","1,500-3,000","3,000-4,500","4,500-6,000","6,000-7,500","7,500-9,000","9,000-10,500","10,500-12,000",">12,000")
rev=T
} else if (input$variable=="temp") {
var = "m.temp"; title = "Average Temp. (\u00b0C)"
rev=T
} else if (input$variable=="range") {
var = "r.temp"; title = "Temp. Range (\u00b0C)"
rev=T
} else if (input$variable=="temp.99") {
var = "temp.99";title = "99th Temp. %ile (\u00b0C)"
rev=T
} else if (input$variable == "uhiq") {
var = "UHI_group"; title = "UHII Quartile"
}

if (input$variable=="uhiq") {
pal <- colorFactor(
palette = c("#5385BC","lightskyblue1","darksalmon","#E34D34"),
domain = eval(parse(text=paste0("zips_shape$",var))),
reverse=F
)
popup_text <-  paste("<b>ZIP Code:</b>", zips_shape$ZIP, "<br>",
"<b>MSA:</b>",zips_shape$CBSA.Title,"<br>",
"<b>",title,":</b>", eval(parse(text=paste0("zips_shape$",var))))

labeller_function <- labelFormat(prefix="")
} else if (input$variable=="uhi") {
pal <- colorNumeric(
palette = c( "#5385BC", "#6C9ECE", "#85B7E0", "#9FD1F2", "#B5DBF2", "#C4C6CE", "#D4B1AA", "#E39C86", "#E7886D", "#E6745A", "#E46047", "#E34D34"),
domain = eval(parse(text=paste0("zips_shape$",var))),
reverse = rev
)

popup_text <-  paste("<b>ZIP Code:</b>", zips_shape$ZIP, "<br>",
"<b>MSA:</b>",zips_shape$CBSA.Title,"<br>",
"<b>",title,":</b>", round(eval(parse(text=paste0("zips_shape$",var))),1))

labeller_function <- labelFormat(prefix = "")
} else if (input$variable%in%c("temp","range","temp.99")) {
pal <- colorNumeric(
palette = hcl.colors(10,palettes[palettes$Variable==input$variable,2]),
domain = eval(parse(text=paste0("zips_shape$",var))),
reverse = rev
)

popup_text <-  paste("<b>ZIP Code:</b>", zips_shape$ZIP, "<br>",
"<b>MSA:</b>",zips_shape$CBSA.Title,"<br>",
"<b>",title,":</b>", round(eval(parse(text=paste0("zips_shape$",var))),1))

labeller_function <- labelFormat(prefix = "")
} else {
pal <- colorBin(
palette = hcl.colors(10,palettes[palettes$Variable==input$variable,2]),
domain = eval(parse(text=paste0("zips_shape$",var))),
bins = bins,
reverse = rev
)

popup_text <-  paste("<b>ZIP Code:</b>", zips_shape$ZIP, "<br>",
"<b>MSA:</b>",zips_shape$CBSA.Title,"<br>",
"<b>",title,":</b>", round(eval(parse(text=paste0("zips_shape$",var))),1))


labeller_function <- function(type, breaks) {
return(labs)
}

}

leafletProxy("leaflet_map") %>%
clearShapes() %>% clearControls() %>%
addPolygons(data=cbsas_shape_full,color="#d7d7d7",weight=1,opacity=0.7,smoothFactor = 0.5,
fillColor = "#e9e9e9",fillOpacity = 0.25) %>%
addPolygons(data=zips_shape,color = ~pal(get(var)), weight=1,
fillColor=~pal(get(var)),
smoothFactor = 0.5,fillOpacity=0.7,
label=lapply(popup_text, htmltools::HTML),
highlight = highlightOptions(color = "lightyellow",weight = 2, bringToFront = T, opacity = 0.7)) %>%
addLegend(data=zips_shape,"bottomright", pal = pal, values = ~get(var),
title = title,
opacity = 1,
labFormat = labeller_function)
}

# Maps for the MSA-Specific Results tabs
if (input$tabs=="MSA-Specific Results" & input$cbsa_tabs == "Interactive Map") { 

rev = F

if (input$forest_variable == "rr.99") {
x="RR.99";xmin="RR.99.low";xmax="RR.99.high";leg_lab="RR (99th vs. MHP)";hover.lab = "RR (95% CI)"
bins <- c(0.5,0.97,1,1.03,1.06,1.09,1.3)
labs <- c("< 0.97","0.97-1.00","1.00-1.03","1.03-1.06","1.06-1.09","> 1.09")

rounding=3
} else if (input$forest_variable == "an.heat") {
x="heat_an";xmin="heat_an_lower";xmax="heat_an_upper";leg_lab="AN (Temp. \u2265 MHP)";hover.lab = "AN (95% CI)"
if (input$forest_type == "Primary") {
bins <- c(-10000,-500,0,500,1000,1500,12000)
labs <- c("< -500","-500-0","0-500","500-1,000","1,000-1,500","> 1,500")
} else {
bins <- c(-10000,-250,0,250,500,750,12000)
labs <- c("< -250","-250-0","0-250","250-500","500-750","> 750")
}
rounding=0
} else if (input$forest_variable == "af.heat") {
x="heat_af";xmin="heat_af_lower";xmax="heat_af_upper";leg_lab="AF (%)";hover.lab = "AF (95% CI)"
bins <- c(-1,-0.1,0,0.1,0.2,0.3,1)
labs <- c("< -0.1","-0.1-0.0","0.0-0.1","0.1-0.2","0.2-0.3","> 0.3")
rounding=3
} else if (input$forest_variable == "ar.heat") {
x="ann_an_rate100k";xmin="ann_an_rate100k_lower";xmax="ann_an_rate100k_upper";leg_lab="AR (per 100k)";hover.lab = "AR (95% CI)"
bins <- c(-100,-5,0,5,15,25,150)
labs <- c("< -5","-5-0","0-5","0-15","15-25","> 25")
rounding=2; rev=T
} else if (input$forest_variable == "mht") {
x="cen";xmin="cen.low";xmax="cen.high";leg_lab="MHT (\u00b0C)";hover.lab = "MHT (95% CI)"
bins <- c(17,21,24,27,30,33,45)
labs <- c("< 21","21-24","24-27","27-30","30-33","> 33")
rounding=1
}

cbsas_shape <- cbsas_shape_full[cbsas_shape_full$group == input$forest_type,]

pal <- colorBin(
palette = hcl.colors(8,palettes_cbsa[palettes_cbsa$Variable==input$forest_variable,2]),
bins = bins,
reverse=rev
)

labeller_function <- function(type, breaks) {
return(labs)
}


if (input$forest_type == "Primary") {
popup_text <- paste0("<b>MSA:</b> ",cbsas_shape$CBSA.Title,
'<br><b>',hover.lab,":</b> ", trimws(format(round(eval(parse(text=paste0("cbsas_shape$",x))),rounding),rounding, big.mark = ',')),
" (",trimws(format(round(eval(parse(text=paste0("cbsas_shape$",xmin))),rounding),rounding,big.mark=',')),", ",
trimws(format(round(eval(parse(text=paste0("cbsas_shape$",xmax))),rounding),rounding,big.mark=',')),")")

leafletProxy("cbsa_map") %>%
clearShapes() %>% clearControls() %>%
addPolygons(data=cbsas_shape,
layerId=cbsas_shape$CBSA.Title,
color = ~pal(get(x)), weight=1,
fillColor=~pal(get(x)),
smoothFactor = 0.5,fillOpacity=0.8,
label=lapply(popup_text, htmltools::HTML),
highlight = highlightOptions(color = "lightyellow",weight = 2, bringToFront = T, opacity = 0.7)) %>%
addLegend(data=cbsas_shape,"bottomright",
pal = pal, values = ~get(x),
labFormat = labeller_function,
title = leg_lab,
opacity = 1)
} else {
cbsas_shape.1 <- cbsas_shape[cbsas_shape$var=="UHII-Q1",]
popup_text.1 <- paste0("<b>MSA:</b> ",cbsas_shape.1$CBSA.Title,
"<br><b>UHII Level:</b> Low UHII",
'<br><b>',hover.lab,":</b> ", trimws(format(round(eval(parse(text=paste0("cbsas_shape.1$",x))),rounding),rounding,big.mark=',')),
" (",trimws(format(round(eval(parse(text=paste0("cbsas_shape.1$",xmin))),rounding),rounding,big.mark=',')),", ",
trimws(format(round(eval(parse(text=paste0("cbsas_shape.1$",xmax))),rounding),rounding,big.mark=',')),")")
cbsas_shape.4 <- cbsas_shape[cbsas_shape$var=="UHII-Q4",]
cbsas_shape.4$CBSA.Title <- paste0(cbsas_shape.4$CBSA.Title," ")
popup_text.4 <- paste0("<b>MSA:</b> ",cbsas_shape.4$CBSA.Title,
"<br><b>UHII Level:</b> High UHII",
'<br><b>',hover.lab,":</b> ", trimws(format(round(eval(parse(text=paste0("cbsas_shape.4$",x))),rounding),rounding,big.mark = ',')),
" (",trimws(format(round(eval(parse(text=paste0("cbsas_shape.4$",xmin))),rounding),rounding,big.mark=',')),", ",
trimws(format(round(eval(parse(text=paste0("cbsas_shape.4$",xmax))),rounding),rounding,big.mark=',')),")")

leafletProxy("cbsa_map") %>%
clearShapes() %>% clearControls() %>%
addPolygons(data=cbsas_shape.1,group="Low UHII",
layerId=cbsas_shape.1$CBSA.Title,
color = ~pal(get(x)), weight=1,
fillColor=~pal(get(x)),
smoothFactor = 0.5,fillOpacity=0.8,
label=lapply(popup_text.1, htmltools::HTML),
highlight = highlightOptions(color = "lightyellow",weight = 2, bringToFront = T, opacity = 0.7)) %>%
addPolygons(data=cbsas_shape.4,group="High UHII",
layerId=cbsas_shape.4$CBSA.Title,
color = ~pal(get(x)), weight=1,
fillColor=~pal(get(x)),
smoothFactor = 0.5,fillOpacity=0.8,
label=lapply(popup_text.4, htmltools::HTML),
highlight = highlightOptions(color = "lightyellow",weight = 2, bringToFront = T, opacity = 0.7)) %>%
addLegend(data=cbsas_shape.4,
"bottomright",
pal = pal, values = ~get(x),
title = leg_lab,
labFormat = labeller_function,
opacity = 1)%>%
addLayersControl(
position = 'topleft',
baseGroups = c("Low UHII","High UHII"),
options = layersControlOptions(collapsed = F)
) %>%
htmlwidgets::onRender("
function() {
var map = this;
var legends = map.controls._controlsById;
function addActualLegend() {
var sel = $('.leaflet-control-layers-base').find('input[type=\"radio\"]:checked').siblings('span').text().trim();
$.each(map.controls._controlsById, (nm) => map.removeControl(map.controls.get(nm)));
map.addControl(legends[sel]);
}
$('.leaflet-control-layers-base').on('click', addActualLegend);
addActualLegend();
}"
)
}
}

})

#############################################################################
######## Outputs for Overall & Subpopulation Results Tab ####################
#############################################################################

# Code to render the plots of the exposure-lag-response curves
output$pooled_curve <- renderPlot({

if (input$type == "pooled") {

curves <- pooled[lapply(pooled, '[[',"type")==input$sub]
curves <- curves[lapply(curves, '[[',"group")==input$subpop]

colors  <- eval(parse(text=paste0('sub_palettes$',paste0(input$sub,input$subpop))))

inds <- c(50,60,70,80,90,99,100)

limits <- c(round(min(pooled[["Primary"]]$tmeancbsa[names(pooled[["Primary"]]$tmeancbsa) %in% paste0(inds,".0%")]),1)-.1,round(max(pooled[["Primary"]]$tmeancbsa[names(pooled[["Primary"]]$tmeancbsa) %in% paste0(inds,".0%")]),1))

if (!(input$sub == "Primary" && input$subpop == "All")) {
if (input$sub != "Primary" && input$subpop != "All") {
groups <- unique(unlist(lapply(curves, '[[',"subgroup")))
if (input$subpop=="Age") {n.col = 3} else { n.col = 2}
par(mfrow = c(1, n.col), xaxs = "i",mar=c(5.1+1, 4.1, 4.1, 2.1-1))
} else {
groups <- c("All")
par(mfrow = c(1, 1),mar=c(5.1+1, 4.1, 2.1, 2.1-1))
}

} else {
if (input$sub != "Primary" && input$subpop != "All") {
groups <- unique(unlist(lapply(curves, '[[',"subgroup")))
if (input$subpop=="Age") {n.col = 3} else { n.col = 2}
par(mfrow = c(1, n.col), xaxs = "i",mar=c(5.1, 4.1, 4.1, 2.1-1))
} else {
groups <- c("All")
par(mfrow = c(1, 1),mar=c(5.1, 4.1, 2.1, 2.1-1))
}
}
curr_min=100;curr_max=0

curves.orig <- curves

plist <- list()

for (j in 1:length(groups)) {

if (length(groups) > 1) {
curves <- curves.orig[lapply(curves.orig, '[[',"subgroup")==groups[j]]
} else {
curves <- curves.orig
}

names(curves)[names(curves) == "sexWomen"] <- "sexFemale"

curves <- curves[order(names(curves))]

for (i in 1:length(curves)) {
pred <- curves[[i]]$pred.metareg
cen <- curves[[i]]$cen.metareg

if (input$sub == "Primary" & input$subpop == "All") {
predvar <- curves[[i]]$tmeancbsa
indlab <- names(predvar) %in% paste0(inds,".0%")
plot(pred,"overall",type="n",
ylim=c(0.9,1.3),xlim=limits,lab=c(6,5,7),axes=F,xlab="",
ylab="RR")
ind1 <- pred$predvar<=cen
ind2 <- pred$predvar>=cen
lines(pred$predvar[ind1],pred$allRRfit[ind1],col=4,lwd=2.5)
lines(pred$predvar[ind2],pred$allRRfit[ind2],col=2,lwd=2.5)
abline(v=cen,lty=2)
axis(1,at=predvar[indlab],labels=inds)
loc = 14.25
mtext("%ile",1,line=1,at=loc,col="black",adj=1,cex=1)
axis(1,at=seq(15,33,2),line=2.5,col="black",col.ticks="black",col.axis="black")
axis(1,at=seq(15,33,1),labels=NA,line=2.5,col="black",col.ticks="black",col.axis="black",tck=-0.009)
mtext(expression(paste(degree, "C")),1,line=3.5,at=loc,col="black",adj=1,cex=1)
axis(2)
} else {
plot(pred,"overall",type="l",lwd=2.5,col=colors[i],ylim=c(0.9,1.3),xlim=limits,axes=F,xlab="",
ylab="RR", ci.arg=list(density=20,col=adjustcolor(colors[i],alpha.f=0.2)))
abline(v=cen,lty=2,col=colors[i])
predvar <- curves[[i]]$tmeancbsa
indlab <- names(predvar) %in% paste0(inds,".0%")

if (i != 1) {axis(1,at=predvar[indlab],labels=NA,col=NA,col.ticks=colors[i],tck=-0.03); tckcol = NA} else { tckcol = colors[i]}
axis(1,at=predvar[indlab],labels=inds,col=NA,col.ticks=tckcol,
col.axis=colors[i],cex.axis=0.95,line=((i-1)/1.5))

if (min(predvar[indlab]) < curr_min) {curr_min<-min(predvar[indlab])}
if (max(predvar[indlab]) > curr_max) {curr_max<-max(predvar[indlab])}

if (i == length(curves)) {
loc = 14.25

axis(1,at=c(curr_min,curr_max),labels=NA,col="black",col.ticks=NA,col.axis=NA)
mtext("%ile",1,line=1,at=loc,col="black",adj=1)

extra <- (1-length(curves))*(2/3)
axis(1,at=seq(15,33,2),line=2.5-extra,col="black",col.ticks="black",col.axis="black")
axis(1,at=seq(15,33,1),labels=NA,line=2.5-extra,col="black",col.ticks="black",col.axis="black",tck=-0.009)
mtext(expression(paste(degree, "C")),1,line=3.5-extra,at=loc,col="black",adj=1)

axis(2)

par(new = F)
} else {
par(new=T)
}
}
}

if (!(input$sub == "Primary" && input$subpop == "All")) {

if (input$sub != "Primary" && input$subpop != "All") {
title(main = paste0(input$subpop, ", ", groups[j]))
legend(x=par("usr")[1]+0.25,y=par("usr")[4], legend=c("Low UHII","High UHII"),
col=colors, lty=1, lwd=2,cex=1,box.lty=0)
} else if (input$sub=="Primary") {

legend(x=par("usr")[1]+0.25,y=par("usr")[4], legend=paste0(unlist(lapply(curves, `[`, c('group'))),', ',unlist(lapply(curves, `[`, c('subgroup')))),
col=colors, lty=1, lwd=2,cex=1,box.lty=0)
} else if (input$subpop == "All") {
legend(x=par("usr")[1]+0.25,y=par("usr")[4], legend=c("Low UHII","High UHII"),
col=colors, lty=1, lwd=2,cex=1,box.lty=0)
}

} 

}

} else if (input$type == "lags") {

curves <- pooled.99[lapply(pooled.99, '[[',"type")==input$sub]
curves <- curves[lapply(curves, '[[',"group")==input$subpop]

colors  <- eval(parse(text=paste0('sub_palettes$',paste0(input$sub,input$subpop))))

if (input$sub != "Primary" && input$subpop != "All") {
groups <- unique(unlist(lapply(curves, '[[',"subgroup")))
if (input$subpop=="Age") {n.col = 3} else { n.col = 2}
par(mfrow = c(1, n.col),mar=c(5.1, 4.1, 4.1, 2.1-1))
} else {
groups <- c("All")
par(mfrow = c(1, 1),mar=c(5.1, 4.1, 2.1, 2.1-1))
}

curves.orig <- curves

plist <- list()

for (j in 1:length(groups)) {

if (length(groups) > 1) {
curves <- curves.orig[lapply(curves.orig, '[[',"subgroup")==groups[j]]
} else {
curves <- curves.orig
}

names(curves)[names(curves) == "sexWomen"] <- "sexFemale"

curves <- curves[order(names(curves))]

for (i in 1:length(curves)) {
pred <- curves[[i]]$pred.99

if (input$sub == "Primary" & input$subpop=="All") {

plot(pred,"overall",ylim=c(0.98,1.03),xlim=c(0,21),axes=T,xlab="Lag",
ylab="RR",lwd=2.5,xlab=c(0:21))
} else {

plot(pred,"overall",col=colors[i],ylim=c(0.98,1.03),xlim=c(0,21),axes=T,xlab="Lag",
ylab="RR",lwd=2.5,xlab=c(0:21),
ci.arg=list(density=20,col=adjustcolor(colors[i],alpha.f=0.2)))

if (input$sub != "Primary" && input$subpop != "All") {
title(main=paste0(input$subpop, ", ", groups[j]))
legend(x=par("usr")[1]+0.25,y=par("usr")[4], legend=c("Low UHII","High UHII"),
col=colors, lty=1, lwd=2,cex=1,box.lty=0)
} else if (input$sub=="Primary") {
legend(x=par("usr")[1]+0.25,y=par("usr")[4], legend=paste0(unlist(lapply(curves, `[`, c('group'))),', ',unlist(lapply(curves, `[`, c('subgroup')))),
col=colors, lty=1, lwd=2,cex=1,box.lty=0)
} else if (input$subpop == "All") {
legend(x=par("usr")[1]+0.25,y=par("usr")[4], legend=c("Low UHII","High UHII"),
col=colors, lty=1, lwd=2,cex=1,box.lty=0)
}

if (i == length(curves)) {
par(new=F)
} else {
par(new=T)
}
}
}
}
}
})

# Informational text for user selection
output$overall_info_text <- renderText({
paste("Select the subpopulation, stratification, and plot type to display:<br><br>")
})

# Figure caption for the exposure-lag-response curve
output$pooled_curve_text <- renderText({

if (input$type == "lags") {
type = "Lag-response at the 99th temperature percentile for the association(s) between daily average temperature and daily cardiovascular disease hospitalizations in the urban cores of 120 contiguous US metropolitan areas, 2000-2017."
} else {
type = "Cumulative exposure-response association(s) between daily average temperature and daily cardiovascular disease hospitalizations in the urban cores of 120 contiguous US metropolitan areas, 2000-2017. The vertical dashed line indicates the location of the minimum hospitalization percentile (MHP)." 
}

if (input$subpop == "All") {
if (input$sub=="UHII") {
caption = paste0(type," Results shown for the entire study population in low and high urban heat island intensity (UHII) areas.")
}  else if (input$sub == "Primary") {
caption = paste0(type, " Results shown for the entire study population.")
}   

} else {
if (input$sub == "Primary") {
if (input$subpop %in% c("Diabetes","CKD")) {
label <- ifelse(input$subpop=="Diabetes",tolower(input$subpop),input$subpop)
caption = paste0(type, " Results shown by ", label, " status.")
} else {
caption = paste0(type, " Results shown by ", tolower(input$subpop), ".")
}
} else if (input$sub == "UHII") {
if (input$subpop %in% c("Diabetes","CKD")) {
label <- ifelse(input$subpop=="Diabetes",tolower(input$subpop),input$subpop)

caption = paste0(type, " Results shown by ", label, " status in low and high urban heat island intensity (UHII) areas.")
} else {
caption = paste0(type, " Results shown by ", tolower(input$subpop), " in low and high urban heat island intensity (UHII) areas.")
}
}
}
})

# Code to render the primary results plots (forest plot + bar plot)
output$pooled_plots <- renderPlotly({

### FOREST PLOT
data.forest <- sub_rr_af_an[,c(1:11,15:17)];  names(data.forest) <- c(names(data.forest)[1:11],"RR","RR.low","RR.high")
data.forest$variable <- rep("Relative Risk (99th vs. MHP)",nrow(data.forest))
data.forest[,c("RR","RR.low","RR.high","cen.metareg")] <- sapply( data.forest[,c("RR","RR.low","RR.high","cen.metareg")],as.numeric)
data.forest <- data.forest[data.forest$type == input$sub & data.forest$group == input$subpop,]
data.forest$uhigroup <- ifelse(data.forest$subtype == "Primary","Overall",ifelse(data.forest$subtype=="Q1","Low UHII","High UHII"))
data.forest$label <- ifelse(data.forest$type=="Primary"&data.forest$group=="All","",
ifelse(data.forest$group=="All",data.forest$uhigroup,paste0(data.forest$group,", ",data.forest$subgroup)))
data.forest$label2 <- ifelse(data.forest$type=="Primary"&data.forest$group=="All","",
ifelse(data.forest$group=="All",data.forest$uhigroup,
ifelse(data.forest$type=="Primary",
	   paste0(data.forest$group,", ",data.forest$subgroup),
	   paste0(data.forest$group,", ",data.forest$subgroup," - ",data.forest$uhigroup)
)))

hover.lab = "RR (95% CI)"; rounding=3; xline=1; ylab = "RR"
if (input$sub != "Primary" & input$subpop != "All") {
pd <- position_dodge(width = 0.4)
col.val <- "uhigroup"
} else {
pd <-  position_dodge(width = 0)
col.val <- "label"
}

if (input$sub != "Primary") {
pal <- rev(eval(parse(text=paste0('sub_palettes$',paste0(input$sub,input$subpop)))))
} else {
pal <- eval(parse(text=paste0('sub_palettes$',paste0(input$sub,input$subpop)))) 
}

facet.name <- c( "Relative Risk (99th vs. MHP)" =  "Relative Risk\n(99th vs. MHP)")
forest.pooled <- ggplot(data=data.forest[data.forest$variable == "Relative Risk (99th vs. MHP)", ], 
aes(x=label,y=RR, ymin=RR.low, ymax=RR.high,color=.data[[col.val]],shape=.data[[col.val]],
text = paste0("<b>",label2,"</b>",
	  '<br><b>',hover.lab,":</b> ", format(round(RR,rounding),rounding)," (",
	  format(round(RR.low,rounding),rounding),", ",
	  format(round(RR.high,rounding),rounding),")",'<br>',
	  '<b>MHP (MHT):</b> ',cen.per.metareg,' (~',round(cen.metareg,1),')'))) +
geom_point(position=pd) + 
scale_color_manual(values=pal) + 
geom_errorbar(width=0.1,position=pd) + theme_bw(base_size=10) + 
geom_hline(yintercept=xline, color='black', linetype='dashed', alpha=.5) +
ylab(ylab) + facet_wrap(~variable,labeller = as_labeller(facet.name)) +
theme(axis.title.x = element_blank(),
strip.background = element_rect(fill = "white",color="white"),
strip.text = element_text(angle=0,face="bold"),
axis.text.x = element_text(angle = 30, hjust=1)
) +
ylim(0.96,1.06)

p1 <- ggplotly(forest.pooled,tooltip="text",source="pooled_plots") %>%
layout(hoverlabel=list(bgcolor="white",align='left'),
yaxis = list(titlefont = list(size = 12),title = ylab), dragmode = F,
legend = list(title = list(text = ""),orientation = "h", x = -0.5, y =-1))  %>% config(displayModeBar = F)

### BAR PLOT
data <- sub_rr_af_an[sub_rr_af_an$type == input$sub&sub_rr_af_an$group == input$subpop,]

if (input$bar.var == "AN") {
lab = "Attributable Number (MHP+)"
hover.lab = "AN (95% CI)";ylab="AN"
facet.name <- c("Attributable Number (MHP+)"="Attributable Number\n(Temp. \u2265 MHP)")
lims <- c(-362,38000); rounding=0
y="ha_heat";ymin="ha_heat_lower";ymax="ha_heat_upper"
} else {
lab = "Attributable Rate (Annual, per 100k)"
hover.lab = "AR (95% CI)";ylab="AR"
facet.name <- c("Attributable Rate (Annual, per 100k)"="Attributable Rate\n(Annual, per 100k)")
lims <- c(-2,50); rounding=2
y="ann_an_rate100k";ymin="ann_an_rate100k_lower";ymax="ann_an_rate100k_upper"
}

data$exposure <- rep(lab,nrow(data)); data$exposure.f = factor(data$exposure, levels=c(lab))

data$uhigroup <- ifelse(data$subtype == "Primary","Overall",ifelse(data$subtype=="Q1","Low UHII","High UHII"))
data$label <- ifelse(data$type=="Primary"&data$group=="All","",
ifelse(data$group=="All",data$uhigroup,paste0(data$group,", ",data$subgroup)))
data$label2 <- ifelse(data$type=="Primary"&data$group=="All","",
ifelse(data$group=="All",data$uhigroup,
ifelse(data$type=="Primary",
paste0(data$group,", ",data$subgroup),
paste0(data$group,", ",data$subgroup," - ",data$uhigroup)
)))


xline=0

sub_palettes.temp <- sub_palettes; sub_palettes.temp[1] <- "grey55"

if (input$sub != "Primary") {
pal <- rev(eval(parse(text=paste0('sub_palettes.temp$',paste0(input$sub,input$subpop)))))
} else {
pal <- eval(parse(text=paste0('sub_palettes.temp$',paste0(input$sub,input$subpop)))) 
}

if (input$sub != "Primary" & input$sub != "All") { pd <- position_dodge(width = 0.9) } else { pd <- position_dodge(width = 0.0)}
bar.pooled <- ggplot(data=data[data$exposure == lab,], 
aes(x=label,y=.data[[y]], ymin=.data[[ymin]], ymax=.data[[ymax]],fill=.data[[col.val]],
text = paste0("<b>",label2,"</b>",
   '<br><b>',hover.lab,":</b> ", format(round(.data[[y]],rounding),big.mark =',',trim=T),
   " (",format(round(.data[[ymin]],rounding),big.mark=',',trim=T),", ",
   format(round(.data[[ymax]],rounding),big.mark=',',trim=T),")",
   '<br><b>','MHP (MHT):</b> ',cen.per.metareg,' (~',round(cen.metareg,1),')'))) + 
geom_col(alpha=0.85,position=pd) +   geom_errorbar(width=.1,color='black',position=pd) + theme_bw(base_size=10) + 
scale_fill_manual(values=pal) + 
geom_hline(yintercept=xline, color='black', linetype='dashed', alpha=.5) +
ylab(ylab) + facet_wrap(~exposure.f,labeller = as_labeller(facet.name)) + 
theme(axis.title.x = element_blank(),
strip.background = element_rect(fill = "white",color="white"),
strip.text = element_text(angle=0,face="bold"),
axis.text.x = element_text(angle = 30, hjust=1)
) + ylim(lims)

p2 <- ggplotly(bar.pooled,tooltip="text",source="pooled_plots") %>%
layout(hoverlabel=list(bgcolor="white",align='left'), yaxis = list(titlefont = list(size = 12),title = ylab), dragmode = F,
legend = list(title = list(text = ""),orientation = "h", x = 0, y =0.125)) %>% 
config(displayModeBar = F)

if (input$sub=="UHII") {
subplot(p1, style(p2,showlegend=F),margin = 0.075,titleY=T)
} else {
subplot(style(p1,showlegend=F), style(p2,showlegend=F),margin = 0.075,titleY=T)
}
})

# Figure caption for the primary results forest + bar plot
output$pooled_plot_text <- renderText({
type = "Heat-related risk and burden"
if (input$subpop == "All") {
if (input$sub=="UHII") {
caption = paste0(type," for the entire study population in low and high urban heat island intensity (UHII) areas, 2000-2017.")
}  else if (input$sub == "Primary") {
caption = paste0(type, " for the entire study population, 2000-2017.")
}   
} else {
if (input$sub == "Primary") {
if (input$subpop %in% c("Diabetes","CKD")) {
label <- ifelse(input$subpop=="Diabetes",tolower(input$subpop),input$subpop)

caption = paste0(type, " by ", label, " status.")
} else {
caption = paste0(type, " by ", tolower(input$subpop), ".")
}
} else if (input$sub == "UHII") {
if (input$subpop %in% c("Diabetes","CKD")) {
label <- ifelse(input$subpop=="Diabetes",tolower(input$subpop),input$subpop)

caption = paste0(type, " by ", label, " status in low and high urban heat island intensity (UHII) areas.")
} else {
caption = paste0(type, " by ", tolower(input$subpop), " in low and high urban heat island intensity (UHII) areas.")
}
}
}
caption = paste0(caption," Metrics include the relative risk (RR) at extreme heat (99th temperature percentile compared to the minimum hospitalization percentile [MHP]) and the heat-attributable (temperatures above the MHP) number (AN) / rate (AR) of cardiovascular hospitalizations.")
})

# Code to render the table of results
output$pooled_table <- DT::renderDataTable({

sub_rr_af_an$Total_HAs <- as.numeric(sub_rr_af_an$Total_HAs)
sub_rr_af_an$Total_Heat_HAs <- as.numeric(sub_rr_af_an$Total_Heat_HAs)


sub_rr_af_an$subpop <- ifelse(sub_rr_af_an$group=="All","All",paste0(sub_rr_af_an$group,", ",sub_rr_af_an$subgroup))
sub_rr_af_an$uhigroup <- ifelse(sub_rr_af_an$type=="Primary","Primary",
ifelse(sub_rr_af_an$subtype == "Q1",
   "Low UHII","High UHII"))

sub_rr_af_an$group_lab <- ifelse(sub_rr_af_an$type == "Primary", ifelse(sub_rr_af_an$group == "All","All",sub_rr_af_an$subpop),
ifelse(sub_rr_af_an$group == "All",
	sub_rr_af_an$uhigroup,paste0(sub_rr_af_an$subpop,"<br>",sub_rr_af_an$uhigroup)))

table <- sub_rr_af_an[sub_rr_af_an$type == input$sub&sub_rr_af_an$group == input$subpop,
c("group_lab","n.cbsas","Num_Zips","Total_HAs","temp.99",
"mhp","mht","RR.99.full","Attr_HAs_Heat","AF_All_Heat","Ann_AN_Rate100k","per_HA_xheat")]

table[is.na(table)] <- "-"

table$per_HAs <- (table$Total_HAs / sub_rr_af_an[sub_rr_af_an$type=="Primary" & sub_rr_af_an$group == "All",]$Total_HAs)*100

table[,c("Total_HAs","Num_Zips")] <- sapply(table[,c("Total_HAs","Num_Zips")],
		function(x)paste0(format(round(x),scientific=F,big.mark=','),''))

table[,c("per_HAs")] <- sapply(table[,c("per_HAs")],
function(x)paste0(round(x,1),"%"))

table$Total_HAs <- paste0(table$Total_HAs," (",table$per_HAs,")")

table[,c("temp.99")] <- sapply(table[,c("temp.99")],function(x)paste0(round(x,1)))

table <- table[,setdiff(colnames(table),c("per_HAs"))]

names(table) <- c("Group","# MSAs","# ZIP Codes","# Hospitalizations (% Total)", "99th Temp. Percentile (\u00b0C)",
"MHP (95% CI)","MHT (\u00b0C) (95% CI)","RR (99th vs. MHP) (95% CI)",
"AN (Temp. \u2265 MHP) (95% CI)","AF (%) (95% CI)", "AR (Annual, per 100k) (95% CI)",
"AN, % Extreme Heat")

type = "Exposure and outcome information and heat-related cardiovascular risk and burden results"
if (input$subpop == "All") {
if (input$sub=="UHII") {
caption = paste0(type," for the entire study population in low and high urban heat island intensity (UHII) areas, 2000-2017.")
}  else if (input$sub == "Primary") {
caption = paste0(type, " for the entire study population, 2000-2017.")
}   
} else {
if (input$sub == "Primary") {
if (input$subpop %in% c("Diabetes","CKD")) {
label <- ifelse(input$subpop=="Diabetes",tolower(input$subpop),input$subpop)

caption = paste0(type, " by ", label, " status, 2000-2017.")
} else {
caption = paste0(type, " by ", tolower(input$subpop), ", 2000-2017.")
}
} else if (input$sub == "UHII") {
if (input$subpop %in% c("Diabetes","CKD")) {
label <- ifelse(input$subpop=="Diabetes",tolower(input$subpop),input$subpop)

caption = paste0(type, " by ", label, " status in low and high urban heat island intensity (UHII) areas, 2000-2017.")
} else {
caption = paste0(type, " by ", tolower(input$subpop), " in low and high urban heat island intensity (UHII) areas, 2000-2017.")
}
}
}

caption = paste0(caption," MSA = Metropolitan Statistical Area; MHP = Minimum Hospitalization Percentile; MHT = Minimum Hospitalization Temperature; RR = Relative Risk; AN = Heat-Attributable Number; AF = Heat-Attributable Fraction; AR = Heat-Attributable Rate.")

DT::datatable(table,
options = list(paging = T,searching = T,dom='t',ordering=T,scrollX = TRUE,
autoWidth = F,
columnDefs = list(
list(className = "nowrap", targets = "_all")
)
),
rownames=FALSE,escape=F,class = 'cell-border stripe',
selection = 'none',
caption = htmltools::tags$caption(
style = 'caption-side: bottom; text-align: left;',
caption
)) 
})

# Bulleted list of the main takeaways
output$main_takeaway <- renderText({
"<ul>
<li>Higher heat-related risk and burden in high UHII areas</li>
<li>Black, female, and older individuals and those with CKD or diabetes had an elevated risk and burden</li>
<li>High UHII had a more pronounced impact among already heat-vulnerable subpopulations</li>
<li>Heat posed a delayed, rather than immediate, threat</li>
</ul>"
})

# Button to download all results for subpopulatuon analyses 
output$downloadAllData <- downloadHandler(
filename <- function() {
paste("data/Overall-Subpop-Results.csv")
},

content <- function(file) {
file.copy("data/Overall-Subpop-Results.csv", file)
},
contentType = "text/csv"
)

#############################################################################
#### Outputs for Exposure & Outcome Maps Tab ################################
#############################################################################

# Code to render the leaflet map
output$leaflet_map <- renderLeaflet({

leaflet() %>%
addProviderTiles(providers$CartoDB.Positron,group="States") %>%
fitBounds(-123.36119,25.13313,-70.02285,48.30850)

})

# Figure caption for the leaflet map
output$leaflet_text <- renderText({
if (input$variable=="uhi") {
part1 = "population-weighted urban heat island intensity (UHII)"
} else if (input$variable == "uhiq") {
part1 = "population-weighted urban heat island intensity (UHII) quartile (Q1 = 'low' UHII areas, Q4 = 'high' UHII areas)"
} else if (input$variable=="hosp") {
part1 = "counts of daily cardiovascular-related hospitalizations among Medicare enrollees (age 65-114)"
} else if (input$variable == "temp") {
part1 = "population-weighted daily average temperature"
} else if (input$variable == "range") {
part1 = "range of population-weighted daily average temperature"
} else if (input$variable == "temp.99") {
part1 = "99th percentile of population-weighted daily average temperature"
} 

if (input$variable%in%c("uhi","uhiq")) {
part2 = "in the urban cores of 120 contiguous US metropolitan statistical areas (MSAs). Additional information on the UHII metric and a link to download the data can be found <a href='https://www.sciencedirect.com/science/article/pii/S0924271620302082' target='_blank'>here</a>."
} else {
part2 = "in the urban cores of 120 contiguous US metropolitan statistical areas (MSAs), 2000-2017."
}

if (input$variable %in% c("temp","range","temp.99")) {
part3 = "Temperature data was downloaded from NOAA's Global Surface Summary of the Day dataset, which can be accessed <a href = 'https://www.ncei.noaa.gov/access/metadata/landing-page/bin/iso?id=gov.noaa.ncdc:C00516' target='_blank'>here</a>."
} else {
part3 = ""
}
part4 = "The light grey shapes delineate the boundaries of the 120 MSAs."
paste("ZIP code-level",part1,part2,part3,part4)
})

# Informational text for user selection
output$map_info_text <- renderText({
paste("Select the exposure, outcome, or urban heat island (UHI) variable to display:<br><br>")
})

#############################################################################
#### Output for MSA-Specific Results Tab ####################################
#############################################################################

# Code to render the forest/bar plot of MSA-specific results
output$forest_plot <- renderPlotly({


tck_size=0.5
if (input$forest_variable == "rr.99") {
x="RR.99";xmin="RR.99.low";xmax="RR.99.high";xline=1;alpha.val=1
xlab="Relative Risk [RR] (99th vs. MHP)";hover.lab = "RR (95% CI)"
xlim = c(0.7,1.4)
rounding = 3
} else if (input$forest_variable == "an.heat") {
x="heat_an";xmin="heat_an_lower";xmax="heat_an_upper";xline=0;alpha.val=0.85
xlab = "Heat-Attributable Number [AN] (Temp. \u2265 MHP)";hover.lab = "AN (95% CI)"
if (input$forest_type == "UHII") {
xlim = c(-2600,4100)
} else {
xlim = c(-4050,12000)
}
rounding = 0
} else if (input$forest_variable == "af.heat") {
x="heat_af";xmin="heat_af_lower";xmax="heat_af_upper";xline=0;alpha.val=1
xlab = "Heat-Attributable Fraction [AF] (%, AN/Total Admits)";hover.lab = "AF (95% CI)"
xlim = c(-0.95, 0.95)
rounding = 3
} else if (input$forest_variable == "ar.heat") {
x="ann_an_rate100k";xmin="ann_an_rate100k_lower";xmax="ann_an_rate100k_upper";xline=0;alpha.val=0.85
xlab = "Heat-Attributable Rate [AR] (per 100,000 beneficiaries)";hover.lab = "AR (95% CI)"
xlim = c(-95,125)
rounding = 2
} else if (input$forest_variable == "mht") {
x="cen";xmin="cen.low";xmax="cen.high";xline=0;alpha.val=1
xlab = "Minimum Hospitalization Temperature [MHT] (\u00b0C)";hover.lab = "MHT (95% CI)"
xlim = c(17,42)
rounding = 1
}

if (input$forest_color=="avg.temp") {
color.lab="Avg. Temp (\u00b0C)"; color="m.temp"
pal = hcl.colors(10,palette="RdYlBu",rev=T)
lims = c(8,24)
brks = seq(8,24,2)
} else if (input$forest_color=="avg.range") { 
color.lab="Avg. Range (\u00b0C)"; color="r.temp"
pal = hcl.colors(10,palette="Purple-Green",rev=T)
lims = c(26,61)
brks = seq(26,61,5)
} else if (input$forest_color=="region") {
color.lab="Region"; color="Region"
pal=c(
"Midwest" = "#82B446",
"South" = "#BB5566",
"Northeast" = "#4682B4",
"West" = "#DDAA33"
)
} else if (input$forest_color=="climate") {
color.lab="Climate Type"; color="Koppen.Simple"
pal= c("Arid" = "#EF4444",
"Cold" = "#394BA0",
"Temperate" = "#009F75",
"Tropical" = "#FAA31B")
} 
if (input$forest_type == "Primary") {
if (input$sort == TRUE & input$forest_color != 'none') {
forest.data.simp <- cbsa_all[cbsa_all$var == input$forest_type,] %>% mutate(CBSA.f = fct_reorder(CBSA.Title, .[[color]]))
tck_size = 0.05
} else {
forest.data.simp <- cbsa_all[cbsa_all$var == input$forest_type,] %>% mutate(CBSA.f = fct_reorder(CBSA.Title, .[[x]]))
}
} else {
forest.temp <- merge(cbsa_all[cbsa_all$subgroup =="Q1",c("CBSA","CBSA.Title",x)],cbsa_all[cbsa_all$subgroup =="Q4",c("CBSA","CBSA.Title",x)],
by=c("CBSA","CBSA.Title"),all.x=T)
names(forest.temp) <- c("CBSA","CBSA.Title","var.q1",'var.q4')
forest.temp$diff <- forest.temp$var.q4 - forest.temp$var.q1
forest.temp$diff <- ifelse(is.na(forest.temp$diff),forest.temp$var.q1-10000,forest.temp$diff)
forest.data.simp <- merge(cbsa_all[cbsa_all$var != "Primary",],forest.temp[,c("CBSA","diff")],by="CBSA")
forest.data.simp <- forest.data.simp %>% mutate(CBSA.f = fct_reorder(CBSA.Title, diff))
}

if (input$forest_type != "Primary") {
color = "var"
pal = c("#5385BC","#E34D34")
color.lab = ""
dodge <- position_dodge(0.6)
} else {
if (input$forest_color == 'none') {
color.lab = ""
}
}


if (input$forest_color %in% c("avg.range","avg.temp")) {
forest.data.simp$r.temp <- round(forest.data.simp$r.temp,2)
forest.data.simp$m.temp <- round(forest.data.simp$m.temp,2)
}

if (input$forest_color == "none" && input$forest_type == "Primary") {
if (input$forest_variable %in% c("an.heat","ar.heat")) {
forest.temp <- ggplot(data=forest.data.simp, 
aes(y=CBSA.f,x=.data[[x]], xmin=.data[[xmin]], xmax=.data[[xmax]],
text = paste0("<b>MSA:</b> ",CBSA.f,
		'<br><b>',hover.lab,":</b> ", trimws(format(round(.data[[x]],rounding),big.mark=','))," (",
		trimws(format(round(.data[[xmin]],rounding),big.mark=',')),", ",
		trimws(format(round(.data[[xmax]],rounding),big.mark=',')),")")
)) 
} else {
forest.temp <- ggplot(data=forest.data.simp, 
aes(y=CBSA.f,x=.data[[x]], xmin=.data[[xmin]], xmax=.data[[xmax]],
text = paste0("<b>MSA:</b> ",CBSA.f,
		'<br><b>',hover.lab,":</b> ", format(round(.data[[x]],rounding),rounding)," (",
		format(round(.data[[xmin]],rounding),rounding),", ",
		format(round(.data[[xmax]],rounding),rounding),")")
)) 
}
} else if (input$forest_color != "none" || input$forest_type == "UHII") {
if (input$forest_variable %in% c("an.heat","ar.heat")) {
if (input$forest_type == "UHII") {
forest.temp <- ggplot(data=forest.data.simp, 
aes(y=CBSA.f,x=.data[[x]], xmin=.data[[xmin]], xmax=.data[[xmax]],fill=.data[[color]],
text = paste0("<b>MSA: </b>",CBSA.f,"<br>",
		  "<b>UHII Level:</b> ",ifelse(.data[[color]]=="UHII-Q1","Low UHII","High UHII"),
		  '<br><b>',hover.lab,":</b> ", trimws(format(round(.data[[x]],rounding),big.mark=","))," (",
		  trimws(format(round(.data[[xmin]],rounding),big.mark=",")),", ",
		  trimws(format(round(.data[[xmax]],rounding),big.mark=",")),")")))
} else {
forest.temp <- ggplot(data=forest.data.simp, 
aes(y=CBSA.f,x=.data[[x]], xmin=.data[[xmin]], xmax=.data[[xmax]],fill=.data[[color]],
text =  paste0("<b>MSA:</b> ",CBSA.f,
		   '<br><b>',hover.lab,":</b> ", trimws(format(round(.data[[x]],rounding),big.mark=","))," (",
		   trimws(format(round(.data[[xmin]],rounding),big.mark=",")),", ",
		   trimws(format(round(.data[[xmax]],rounding),big.mark=",")),")",
		   '<br><b>',color.lab,':</b> ',.data[[color]])))
}
} else {
if (input$forest_type == "UHII") {
forest.temp <- ggplot(data=forest.data.simp, 
aes(y=CBSA.f,x=.data[[x]], xmin=.data[[xmin]], xmax=.data[[xmax]],color=.data[[color]],
text = paste0("<b>MSA: </b>",CBSA.f,"<br>",
		  "<b>UHII Level:</b> ",ifelse(.data[[color]]=="UHII-Q1","Low UHII","High UHII"),
		  '<br><b>',hover.lab,":</b> ", format(round(.data[[x]],rounding),rounding)," (",
		  format(round(.data[[xmin]],rounding),rounding),", ",
		  format(round(.data[[xmax]],rounding),rounding),")"
)))
} else {
forest.temp <- ggplot(data=forest.data.simp, 
aes(y=CBSA.f,x=.data[[x]], xmin=.data[[xmin]], xmax=.data[[xmax]],color=.data[[color]],
text =  paste0("<b>MSA:</b> ",CBSA.f,
		   '<br><b>',hover.lab,":</b> ", format(round(.data[[x]],rounding),rounding)," (",
		   format(round(.data[[xmin]],rounding),rounding),", ",
		   format(round(.data[[xmax]],rounding),rounding),")",
		   '<br><b>',color.lab,':</b> ',.data[[color]])))
}
}
}

if (input$forest_variable %in% c("an.heat","ar.heat")) {
if (input$forest_type == "UHII") {
forest.temp <- forest.temp + geom_col(position=dodge) + 
geom_errorbarh(height=2,size=tck_size,color='black',position=dodge) + 
theme_bw(base_size=10) + 
geom_vline(xintercept=xline, color='black', linetype='dashed', alpha=.5) +
theme(axis.title.y = element_blank()) +
xlab(xlab)
} else {
forest.temp <- forest.temp + geom_col() + 
geom_errorbarh(height=2,size=tck_size,color='black') + theme_bw(base_size=10) + 
geom_vline(xintercept=xline, color='black', linetype='dashed', alpha=.5) +
theme(axis.title.y = element_blank()) +
xlab(xlab)
}

} else {
if (input$forest_type == "UHII") {
forest.temp <- forest.temp + geom_point(position=dodge) + 
geom_errorbarh(height=2,size=tck_size,position=dodge) + theme_bw(base_size=10) + 
geom_vline(xintercept=xline, color='black', linetype='dashed', alpha=.5) +
theme(axis.title.y = element_blank()) +
xlab(xlab)
} else {
forest.temp <- forest.temp + geom_point() + 
geom_errorbarh(height=2,size=tck_size) + theme_bw(base_size=10) + 
geom_vline(xintercept=xline, color='black', linetype='dashed', alpha=.5) +
theme(axis.title.y = element_blank()) +
xlab(xlab)
}
}

if (input$forest_color%in%c("avg.range","avg.temp") && input$forest_type == "Primary") {
if (input$forest_variable %in% c("an.heat","ar.heat")) {
forest.temp <- forest.temp + 
scale_fill_gradientn(colours=alpha(pal,alpha.val),guide = 'colorbar',
oob = scales::squish,name=color.lab, limits = lims, breaks = brks)
} else {
forest.temp <- forest.temp + scale_color_gradientn(colours=pal,guide = 'colorbar',
				   oob = scales::squish,name=color.lab,
				   limits = lims, breaks = brks)
}


} else if ((input$forest_color%in%c("region","climate") && input$forest_type == "Primary" )|| input$forest_type == "UHII"){
if (input$forest_variable %in% c("an.heat","ar.heat")) {
forest.temp <-  forest.temp + scale_fill_manual(values = alpha(pal,alpha.val)) 
} else {
forest.temp <-  forest.temp + scale_colour_manual(values = pal) 

}

}

forest.temp <- forest.temp + xlim(xlim)

p1 <- suppressWarnings(ggplotly(forest.temp,tooltip="text",source="forest_plot") %>%
layout(hoverlabel=list(bgcolor="white",align='left'),legend = list(title = list(text = color.lab))))

plot <- plotly_build(p1)

if (input$forest_type == "UHII") {
plot$x$data[[1]]$name <- "Low UHII"; plot$x$data[[2]]$name <- "High UHII"
} 

event_register(plot,'plotly_click') 

if ((input$forest_color == "none" && input$forest_type == "UHII") ||
input$forest_type == "Primary") {
plot
}

})

# Only generate forest/bar plot click data when on the "MSA-Specific Results" tab
click_data <- reactive({
if (input$tabs=="MSA-Specific Results") {
event_data("plotly_click", source = "forest_plot")
}
})

# Observe event to update curve and table to MSA selected in forest/bar plot
observeEvent(click_data(),{  

event_data <- click_data()

if(!is.null(event_data$pointNumber)){

if (input$forest_type == "Primary") {
cbsa_temp <- cbsa_all[cbsa_all$var == input$forest_type,]
} else {
if (event_data$curveNumber %in% c(0,2)) { # Q1
cbsa_temp <- cbsa_all[cbsa_all$var == "UHII-Q1",]
} else { # Q4
cbsa_temp <- cbsa_all[cbsa_all$var == "UHII-Q4",]
}
}
updateSelectInput(session,"cbsa_choice",selected=cbsa_temp[event_data$pointNumber+1,]$CBSA.Title)

}
})

# Code to render the leaflet map of MSA-specific results
output$cbsa_map <- renderLeaflet({

if (input$forest_type == "Primary") {
cbsas_shape <- cbsas_shape_full[cbsas_shape_full$group == input$forest_type,]

leaflet(cbsas_shape) %>% clearShapes() %>% clearControls() %>%
addProviderTiles(providers$CartoDB.Positron, group="States") %>%
fitBounds(-123.36119,25.13313,-70.02285,48.30850)
} else {
leaflet() %>% clearShapes() %>% clearControls() %>%
addProviderTiles(providers$CartoDB.Positron, group="States") %>%
fitBounds(-123.36119,25.13313,-70.02285,48.30850)
}

})

# Observe event to update curve and table to MSA selected in map
observeEvent(input$cbsa_map_shape_click, {

click <- input$cbsa_map_shape_click

if(!is.null(click$id)){
updateSelectInput(session,"cbsa_choice",selected=trimws(click$id))

}
}) 

# Observe event to update user selections based on the tab selected
observeEvent (input$cbsa_tabs, {
if(input$cbsa_tabs=="Interactive Map"){ 
shinyjs::disable("forest_color")
shinyjs::reset("forest_color")
shinyjs::disable("sort")
shinyjs::reset("sort")
} else {
if (input$forest_type == "Primary") {
shinyjs::enable("forest_color")
shinyjs::enable("sort")
}
}
})

# Observe event to allow/not allow sorting by MSA-level characteristic
observeEvent (input$forest_color, {
if(input$forest_color=="none"){ 
shinyjs::disable("sort")
shinyjs::reset("sort")
} else {
shinyjs::enable("sort")
}
})

# Observe event to allow/not allow sorting by MSA-level characteristic
observeEvent (input$forest_type, {
if (input$cbsa_choice %in% unique(cbsa_all[cbsa_all$group == input$forest_type,]$CBSA.Title)) {
updateSelectInput(session,"cbsa_choice",choices=unique(cbsa_all[cbsa_all$group == input$forest_type,]$CBSA.Title),
selected= input$cbsa_choice)
} else {
updateSelectInput(session,"cbsa_choice",choices=unique(cbsa_all[cbsa_all$group == input$forest_type,]$CBSA.Title),
selected= "Akron, OH")
}

if (input$forest_type == "Primary") {
shinyjs::enable("forest_color")
if(input$forest_color=="none"){ 
shinyjs::disable("sort")
shinyjs::reset("sort")
} else {
shinyjs::enable("sort")
}      
} else {
shinyjs::disable("forest_color")
shinyjs::disable("sort")
shinyjs::reset("forest_color")
shinyjs::reset("sort")
}
})

# Code to render MSA-specific exposure-response curve
output$cbsa_curve <- renderPlot({

if (input$forest_type != "Primary") {
par(mar=c(5.1+1, 4.1, 4.1, 2.1))
} else {
par(mar=c(5.1, 4.1, 4.1, 2.1))
}

if (input$cbsa_choice %in% unique(cbsa_all[cbsa_all$group == input$forest_type,]$CBSA.Title)) {
idx = cbsa_all[cbsa_all$CBSA.Title==input$cbsa_choice & cbsa_all$group == input$forest_type,]$X
} else {
idx = cbsa_all[cbsa_all$CBSA.Title=="Akron, OH" & cbsa_all$group == input$forest_type,]$X
}

if (input$forest_type == "Primary") {
preds <- list(CBSA.preds[[input$forest_type]][[idx]])
predvars <- list(CBSA.tmeans[[input$forest_type]][[idx]])
} else {
if (length(idx) == 2) {
preds <- list(CBSA.preds[["UHII-Q1"]][[idx[1]]],CBSA.preds[["UHII-Q4"]][[idx[2]]])
predvars <- list(CBSA.tmeans[["UHII-Q1"]][[idx[1]]],CBSA.tmeans[["UHII-Q4"]][[idx[2]]])
colors <- c("#5385BC","#E34D34")
curr_min=100;curr_max=0
} else {
preds <- list(CBSA.preds[["UHII-Q1"]][[idx]])
predvars <- list(CBSA.tmeans[["UHII-Q1"]][[idx]])
colors <- c("#5385BC")
curr_min=100;curr_max=0

}
}

cens <- cbsa_all[cbsa_all$CBSA.Title==input$cbsa_choice & cbsa_all$group == input$forest_type,]$cen

inds <- c(50,60,70,80,90,99,100)


for (i in 1:length(preds)) {

pred <- preds[[i]]
predvar <- predvars[[i]]
cen <- cens[i]


indlab <- names(predvar) %in% paste0(inds,"%")

limits <- c(round(min(predvar[indlab]),1)-.1,round(max(predvar[indlab]),1))


if (input$forest_type == "Primary") {
plot(pred,"overall",type="n",
ylim=c(0.5,1.5),xlim=limits,lab=c(6,5,7),axes=F,xlab="",
ylab="RR")
ind1 <- pred$predvar<=cen
ind2 <- pred$predvar>=cen

lines(pred$predvar[ind1],pred$allRRfit[ind1],col=4,lwd=2.5)
lines(pred$predvar[ind2],pred$allRRfit[ind2],col=2,lwd=2.5)
abline(v=cen,lty=2)
axis(1,at=predvar[indlab],labels=inds)
loc = par("usr")[1]-0.05*diff(par("usr")[1:2])
mtext("%ile",1,line=1,at=loc,col="black",adj=1)
min <- floor(min(predvar[indlab]))-1; max <- ceiling(max(predvar[indlab]))+1
axis(1,at=seq(min,max,2),line=2.5,col="black",col.ticks="black",col.axis="black")
axis(1,at=seq(min,max,1),labels=NA,line=2.5,col="black",col.ticks="black",col.axis="black",tck=-0.009)

mtext(expression(paste(degree, "C")),1,line=3.5,at=loc,col="black",adj=1)
axis(2)
} else {

plot(pred,"overall",type="l",lwd=2.5,col=colors[i],ylim=c(0.5,1.5),xlim=limits,axes=F,xlab="",
ylab="RR", ci.arg=list(density=20,col=adjustcolor(colors[i],alpha.f=0.2)))
abline(v=cen,lty=2,col=colors[i])

if (i != 1) {axis(1,at=predvar[indlab],labels=NA,col=NA,col.ticks=colors[i],tck=-0.03); tckcol = NA} else { tckcol = colors[i]}
axis(1,at=predvar[indlab],labels=inds,col=NA,col.ticks=tckcol,
col.axis=colors[i],cex.axis=0.95,line=((i-1)/1.5))

if (min(predvar[indlab]) < curr_min) {curr_min<-min(predvar[indlab])}
if (max(predvar[indlab]) > curr_max) {curr_max<-max(predvar[indlab])}

if (i == length(preds)) {
loc = par("usr")[1]-0.05*diff(par("usr")[1:2])

axis(1,at=c(curr_min,curr_max),labels=NA,col="black",col.ticks=NA,col.axis=NA)
mtext("%ile",1,line=1,at=loc,col="black",adj=1)

extra <- (1-length(preds))*(2/3)

axis(1,at=seq(floor(curr_min),ceiling(curr_max),2),line=2.5-extra,col="black",col.ticks="black",col.axis="black")
axis(1,at=seq(floor(curr_min),ceiling(curr_max),1),labels=NA,line=2.5-extra,col="black",col.ticks="black",col.axis="black",tck=-0.009)

mtext(expression(paste(degree, "C")),1,line=3.5-extra,at=loc,col="black",adj=1)

axis(2)

if (length(preds) == 2) { leg = c("Low UHII","High UHII")} else { leg = c("Low UHII")}

legend(x=par("usr")[1]+0.25,y=par("usr")[4], legend=leg,
col=colors, lwd=2,cex=1,box.lty=0)

par(new = F)
} else {
par(new=T)
}

}
}


})

# Informational text for user selection
output$cbsa_info_text <- renderText({
paste("Select the variable and stratification to display. For overall results, you may also choose to color and sort the variable by MSA-level characteristics:<br><br>")
})

# Download button for all MSA-level results
output$downloadMSAData <- downloadHandler(
filename <- function() {
paste("data/MSA-Level-Results.csv")
},

content <- function(file) {
file.copy("data/MSA-Level-Results.csv", file)
},
contentType = "text/csv"
)

# Code to render table of MSA-specific results
output$cbsa_table <- DT::renderDataTable({

if (input$cbsa_choice %in% unique(cbsa_all[cbsa_all$group == input$forest_type,]$CBSA.Title)) {
table <- cbsa_all[cbsa_all$CBSA.Title==input$cbsa_choice & cbsa_all$group == input$forest_type,]
} else {
table <- cbsa_all[cbsa_all$CBSA.Title=="Akron, OH" & cbsa_all$group == input$forest_type,]
}

table$per_x_heat <- paste0(round((table$x_heat_an/table$heat_an)*100,1),"")
table$RR.99 <- paste0(format(round(table$RR.99,3),3), " (",format(round(table$RR.99.low,3),3),", ",format(round(table$RR.99.high,3),3),")")
table$heat_af <- paste0(format(round(table$heat_af,3),3), " (",format(round(table$heat_af_lower,3),3),", ",format(round(table$heat_af_upper,3),3),")")
table$heat_an <- paste0(format(round(table$heat_an,0),big.mark=',',trim=T), " (",
format(round(table$heat_an_lower,0),big.mark=',',trim=T),", ",
format(round(table$heat_an_upper,0),big.mark=',',trim=T),")")
table$heat_ar <- paste0(format(round(table$ann_an_rate100k,2),big.mark=',',trim=T), " (",
format(round(table$ann_an_rate100k_lower,2),big.mark=',',trim=T),", ",
format(round(table$ann_an_rate100k_upper,2),big.mark=',',trim=T),")")
table$temp.99 <- round(table$temp.99,1)

table$mht <- paste0(format(round(table$cen,1),big.mark=',',trim=T), " (",
format(round(table$cen.low,1),big.mark=',',trim=T),", ",
format(round(table$cen.high,1),big.mark=',',trim=T),")")

table$mhp <- paste0(format(round(table$cen.per,1),big.mark=',',trim=T), " (",
format(round(table$cen.per.low,1),big.mark=',',trim=T),", ",
format(round(table$cen.per.high,1),big.mark=',',trim=T),")")

if (input$forest_type == "Primary") {
all_hosp <- sum(cbsa_all[cbsa_all$var == input$forest_type,]$tot_hosp)
all_heat_hosp <- sum(cbsa_all[cbsa_all$var == input$forest_type,]$tot_heat_hosp)
table$tot_hosp_per <-round((table$tot_hosp/all_hosp)*100,1)
table$tot_heat_hosp_per <- round((table$tot_heat_hosp/all_heat_hosp)*100,1)
} else {
all_hosp1 <- sum(cbsa_all[cbsa_all$var == "UHII-Q1",]$tot_hosp)
all_heat_hosp1 <- sum(cbsa_all[cbsa_all$var == "UHII-Q1",]$tot_heat_hosp)
all_hosp4 <- sum(cbsa_all[cbsa_all$var == "UHII-Q4",]$tot_hosp)
all_heat_hosp4 <- sum(cbsa_all[cbsa_all$var == "UHII-Q4",]$tot_heat_hosp)
table$tot_hosp_per <- c(round(( table[table$var == "UHII-Q1",]$tot_hosp/all_hosp1)*100,1), 
round(( table[table$var == "UHII-Q4",]$tot_hosp/all_hosp4)*100,1))
table$tot_heat_hosp_per <- c(round(( table[table$var == "UHII-Q1",]$tot_heat_hosp/all_heat_hosp1)*100,1),
round(( table[table$var == "UHII-Q4",]$tot_heat_hosp/all_heat_hosp4)*100,1))

}

table$tot_hosp <- format(table$tot_hosp,big.mark=',',trim=T)
table$tot_heat_hosp <- format(table$tot_heat_hosp,big.mark=',',trim=T)
table$tot_hosp_per_lab <- paste0(table$tot_hosp, " (",table$tot_hosp_per,"%)")
table$tot_heat_hosp_per_lab <- paste0(table$tot_heat_hosp, " (",table$tot_heat_hosp_per,"%)")

table <- data.frame(label=colnames(table),data=t(table))

table <- table[c("n.zips","tot_hosp_per_lab","temp.99",
"mhp","mht","RR.99","heat_an","heat_af","heat_ar"),]

rownames(table) <- NULL

table$label <- c("<b># ZIP Codes</b>","<b># Hospitalizations (% Total)</b>","<b>99th Temp. %ile (\u00b0C)</b>",
"<b>MHP (95% CI)</b>","<b>MHT (\u00b0C) (95% CI)</b>","<b>RR (99th vs. MHP) (95% CI)</b>",
"<b>AN (Temp. \u2265 MHP) (95% CI)</b>","<b>AF (%) (95% CI)</b>","<b> AR (Annual, per 100k) (95% CI)</b>")

if (input$forest_type=="Primary") {
caption = paste0('Exposure and outcome information and heat-related cardiovascular risk and burden results for ',input$cbsa_choice,', 2000-2017.')
colnames = c("Overall")            
} else {
caption = paste0('Exposure and outcome information and heat-related cardiovascular risk and burden results for ',input$cbsa_choice,", in low and high urban heat island intensity (UHII) areas, 2000-2017.")
if (ncol(table) == 3) {
colnames = c("Low UHII","High UHII")
} else {
colnames = c("Low UHII")
}
}

caption <- paste0(caption," ", input$cbsa_choice, " is located in the ", 
unique(cbsa_all[cbsa_all$CBSA.Title==input$cbsa_choice & cbsa_all$group == input$forest_type,]$Region),
" and has a climate type of: ", 
unique(cbsa_all[cbsa_all$CBSA.Title==input$cbsa_choice & cbsa_all$group == input$forest_type,]$Koppen.Description))

caption <- paste0(caption, ". MSA = Metropolitan Statistical Area; MHP = Minimum Hospitalization Percentile; MHT = Minimum Hospitalization Temperature; RR = Relative Risk; AN = Heat-Attributable Number; AF = Heat-Attributable Fraction; AR = Heat-Attributable Rate.")
DT::datatable(table, 
options = list(paging = FALSE,searching = FALSE,dom='t',ordering=F),

selection = 'none',rownames=FALSE,escape=FALSE,class = 'cell-border stripe',
caption = htmltools::tags$caption(
style = 'caption-side: bottom; text-align: left;',
caption
),
colnames = colnames) 
})

# Text to identify which MSA is currently selected
output$cbsa_title <- renderText({
paste0("Results for <b>",input$cbsa_choice,"</b>:")
})

# Bulleted list of key takeaways
output$msa_takeaway <- renderText({
"<ul>
<li>Significant variation in the MSA-level risk and burden, overall and by UHII level</li>
<li>No clear geographic pattern for which MSAs had the highest heat-related risk and burden</li>
<li>Overall: 66% of MSAs had a RR (99th vs. MHP) > 1 </li>
<li>Low UHII: 60% of MSAs had a RR (99th vs. MHP) > 1 </li>
<li>High UHII: 78% of MSAs had a RR (99th vs. MHP) > 1 </li>
</ul>"
})


#############################################################################
#### Output for About Tab ###################################################
#############################################################################  

output$about_text <- renderText({
paste0(
"This dashboard is associated with the manuscript <b><i>Urban Heat Island Impacts on Heat-Related Cardiovascular Morbidity: A Time Series Analysis of Older Adults in US Metropolitan Areas</i></b>.",
" It allows for interaction with the manuscript's primary results - the heat-related cardiovascular risk and burden across the urban cores of 120 contiguous US metropolitan statistical areas (MSAs), 2000-2017. The results are available for the entire study population, different subpopulations, and in low and high urban heat island intensity (UHII) areas ('Overall & Subpopulation Results' tab).",
" It also allows for interaction with the MSA-level risk and burden, overall and in low and high UHII areas ('MSA-Specific Results' tab).", 
" All results can be downloaded on their respective tabs.",
" Additionally, users can explore the ZIP code-level temperature, UHII, and Medicare hospitalization data used in the analyses ('Exposure & Outcome Maps').",
"<br><br>",
"Details on the datasets and methods used as well as a discussion of all results and sensitivity analyses can be found in the associated manuscript.",
"<br><br>",
"For any questions, please email: <a href='mailto:cleland.stephanie@epa.gov'>cleland.stephanie@epa.gov</a> or <a href='mailto:rappold.ana@epa.gov'>rappold.ana@epa.gov</a>.",
"<br><br>",
"<b>Abstract</b>",
"<br><i>Background.</i> The United States (US) population largely resides in urban areas where climate change is projected to increase temperatures and the frequency of heat events. Extreme heat has been linked to increased cardiovascular disease (CVD) risk, yet little is known about this association across urban heat islands (UHIs).",
"<br><i>Objective.</i> To identify the US urban populations at the highest risk of heat-related CVD morbidity and characterize the heat-attributable burden.",
"<br><i>Methods.</i> We obtained daily counts of CVD hospitalizations among Medicare enrollees, aged 65-114, in 120 metropolitan statistical areas (MSAs) in the contiguous US between 2000-2017. Local average temperatures were estimated by interpolating daily monitor observations. ",
"A quasi-Poisson regression with distributed lag non-linear models was applied to estimate MSA-specific associations between temperature and hospitalization. These associations were pooled using multivariate meta-analyses. Stratified analyses were performed by age, sex, race, and chronic condition status in low and high UHI intensity (UHII) areas, estimated from satellite-derived temperatures in urban versus non-urban areas. We also calculated the number of CVD hospitalizations attributable to heat. ",
"<br><i>Results.</i> Extreme heat (99th percentile, ~28.6C) increased CVD hospitalization risk by 1.5% (95% CI: 0.4%, 2.6%), with considerable MSA-to-MSA variation. There were an estimated 37,028 (95% CI: 35,741, 37,988) heat-attributable admissions, with most due to extreme temperatures. The risk difference between high and low UHII areas was 1.4% (2.4% [95% CI: 0.4%, 4.3%] in high vs. 1.0% [95% CI: -0.8%, 2.8%] in low). ",
"High UHII accounted for 35% of the total burden and disproportionately impacted already heat-vulnerable populations, with a higher heat-related risk and burden among female, Black, and older (age 75-114) enrollees and those with diabetes and chronic kidney disease.",
"<br><i>Conclusions.</i> Extreme heat increases the risk and burden of cardiovascular morbidity among older adults in US urban areas. UHIs exacerbate the adverse impacts of heat, especially among those with existing vulnerabilities.",
"<br><br>",
"<b>Authors:</b> Stephanie E. Cleland, William Steinhardt, Lucas M. Neas, J. Jason West, Ana G. Rappold"
)  
})

}

shinyApp(ui = ui, server = server)