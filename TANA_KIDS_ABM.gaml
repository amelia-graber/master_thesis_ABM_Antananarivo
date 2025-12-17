/**
* Name: TANA KISS ABM
* Author: Amélia Graber
*/

model TanaKids

// Global Model Definition
global {
	
	// season attributes
	seasons season; //season species
	string WET <- "wet" const: true; // define wet as a string
	string DRY <- "dry" const: true; // define dry as a string
	
	// Flood water depths, chose either the first line (2017 - 2022) or the second line (2022 - 2030), 0m for dry season
	//list<float> water_depths_list <- [0, 0.88, 0, 1.08, 0, 2.8, 0, 1.102, 0, 2, 0, 0]; // flood water depths from 2017 to 2022 (calibration & validation)
	list<float> water_depths_list <- [0, 2.04, 0, 0, 0, 0, 0, 0.86, 0, 0.86, 0, 1.25, 0, 0, 0, 0.86, 0, 0, 0, 0, 0, 0.86, 0, 1.57, 0, 0.86, 0, 0, 0]; //flood water depths from 2022 to 2030 (randomly chosen based on impact-return period curve, stays constant for all simulations)
	
	// land attributes
	float max_plot_area <- 2000 #m2; // area per farming plot, all same size, necessary to create plots if no shapefile available, keep same if using shapefiles provided
	float max_soil_depth <- 1.966560; // maximum soil depth (heighest possible soil depth at t = 0)
	float base_price <- 21939.34; // minimum price of land (can become more expensive due to characteristics e.g. closeness to roads
	float price_param <- 10000.0; // parameter to vary land price
	float market_income <- 11092238.0; // income from market gardening for one season on 1 ha
	float rice_income <- 9151563.0; // income from rice making for one season on 1 ha
	float mg_water_height <- 0.8645458; // maximum water height for market gardening to be possible (if more => swamp)
	float brick_price_param <- 0.03411175; // parameter to vary brick price depending on distance to roads (further away => bricks are sold for cheaper)
	float brick_price <- 75.0; 
	
	// tracking variables
	int share_urban <- plots count (each.land_use = 6);// variable to track number of plots urban
	int share_swamp <- plots count (each.land_use = 4);// variable to track number of plots swamp
	int share_mg <- plots count (each.land_use = 2);// variable to track number of plots market gardening
	int share_bare <- plots count (each.land_use = 3);// variable to track number of plots bare
	int share_brick <- plots count (each.land_use = 5);// variable to track number of plots brick
	int share_rice <- plots count(each.land_use = 1); // variable to track number of plots rice
	
	// households attributes
	int num_households; // Variable to save how many households exist (defined according to the number of farming plots)
	int avg_nb_plots <- 4; // average number of plots per household
	float max_dist_plots <- 3000#m; // max distance between plots of one household
	float min_income <- 519040.5; // minimum income per household member for food subsistence
	float rate_pop_increase <- 0.01239064;// rate of population increase in the plains
	float mg_necessary_ressources <- 1.991022; // factor of minimum income per household necessary for market gardening (needs ressources)
	int num_hh_per_plot <- 10;
	float share_hungry;
	float tot_income;
	float tot_income_with_land;
	
	// industry attributes
	float likelihood_of_new_ind <- 0.1763063; // likelihood of new ind every year

	// DATA FOR NORTH POLDER IN 2022, COMMENT OUT WITH /* X */ IF OTHER STARTING DATA NECESSARY

	// create environment in shape of one part of Tana's plains  (< 1260 meter above sea level & <10° slope) in Brouillet 2025's study area 
	file initial_area <- file("north_polder/plains_shp/one_plains_constance_Dissolve.shp");//plains
	geometry shape  <- envelope(initial_area); //shape of environment is a square around plains from shapefile
	
	// read in area that is swamp (will have lower soil at t = 0
	file swamp_shp <- file("north_polder/swamp_shp/Tana_LCM_2022_marais_north_poulder.shp");
	
	//read in shapefiles of geographical features
	file shape_irrigation <- file("irrigation_shp/canaux_irrigations_Clip.shp"); //irrigation channels 
	file shape_rivers <- file("river_shp/river__Clip.shp");//rivers 
	file shape_road <- file("transport_shp/transportation__Clip.shp");//roads 
	file shape_industry <- file("north_polder/industry_shp/Tana_LCM_2022_industry_north_poulder.shp");//industry
	file shape_urban <- file("north_polder/urban_shp/Tana_LCM_2022_urban_housing_north_poulder.shp");//urban
	file shape_plains <- file ("north_polder/plains_shp/one_plains_constance_Dissolve.shp");//plains
	// can chose either north polder or east polder plots, make sure same as other geographical elements (not all are polder specific)
	file shape_plots <- file("plots_shp_north_polder/plots.shp"); // farming plots, can also create them using code below (for example with changed area defined above)
	file dem_file <- file("dem/raster_elev.asc");
	
	// DATA FOR EAST POLDER IN 2017, COMMENT OUT WITH /* X */ IF OTHER STARTING DATA NECESSARY
	
	/*file initial_area <- file("east_poulder/east_poulder.shp");//plains
	geometry shape <- envelope(initial_area); //shape of environment is a square around plains from shapefile
	// read in area that is swamp (will have lower soil at t = 0
	file swamp_shp <- file("east_poulder/Tana_LandCoverMap_2017_marais_east.shp");
	//read in shapefiles of geographical features 
	file shape_irrigation <- file("irrigation_shp/canaux_irrigations_Clip.shp"); //irrigation channels
	file shape_rivers <- file("river_shp/river__Clip.shp");//rivers
	file shape_road <- file("transport_shp/transportation__Clip.shp");//roads
	file shape_industry <- file("industry_shp/Tana_LandCoverMap_2017_industry_clip.shp");//industry
	file shape_urban <- file("east_poulder/Tana_LandCoverMap_2017_urban_east.shp");//urban
	file shape_plains <- file ("east_poulder/east_poulder.shp");//plains
	file shape_plots <- file("plots_shp_east_polder/plots.shp");
	file dem_file <- file("dem/raster_elev.asc");*/
	
	// DATA FOR NORTH POLDER IN 2017, COMMENT OUT WITH /* X */ IF OTHER STARTING DATA NECESSARY
	
	/*file initial_area <- file("north_polder/plains_shp/one_plains_constance_Dissolve.shp");//plains
	geometry shape <- envelope(initial_area); //shape of environment is a square around plains from shapefile
	// read in area that is swamp (will have lower soil at t = 0
	file swamp_shp <- file("north_polder/swamp_shp/Tana_LCM_2022_marais_north_poulder.shp");
	read in shapefiles of geographical features 
	file shape_irrigation <- file("irrigation_shp/canaux_irrigations_Clip.shp"); //irrigation channels
	file shape_rivers <- file("river_shp/river__Clip.shp");//rivers
	file shape_road <- file("transport_shp/transportation__Clip.shp");//roads
	file shape_industry <- file("north_polder/industry_shp/Tana_LandCoverMap_2017_industry_clip.shp");//industry
	file shape_urban <- file("north_polder/urban_shp/Tana_LandCoverMap_2017__Clip_urban.shp");//urban
	file shape_plains <- file ("north_polder/plains_shp/one_plains_constance_Dissolve.shp");//plains
	file dem_file <- file("dem/raster_elev.asc");
	file shape_plots <- file("plots_shp_north_polder/plots.shp");*/
	
	// create color palettes for aspects
	
	// land use 
	list<rgb> plot_colors <- [ 
		#lightgreen, // rice
		#darkgreen, // market gardening
		#brown, // bare
		#blue, // swamp
		#orange, // brick
		#gray, //urban
		#black // unassigned
	];
	
	// soil height
	list<rgb> soil_colors <- [
    rgb(255, 200, 124),  // light sand
    rgb(255, 180, 90),   // golden sand
    rgb(255, 160, 60),   // ochre
    rgb(255, 140, 0),    // orange clay
    rgb(205, 92, 92),    // rosy soil
    rgb(139, 0, 0),      // dark red
    rgb(60, 40, 30),     // humus
    rgb(30, 20, 15)      // almost black earth
	];
	
	// Initialization of model
	init {
		create seasons number: 1 {
			season <- self;
		}
		
		//create geographical features' species 
		create irr from: shape_irrigation;
		create river from: shape_rivers;
		create road from: shape_road;
		create swamp from: swamp_shp;
		create industry from: shape_industry;
		create urban from: shape_urban;
		
		//create plots of land 
		create plots from: shape_plots; // use plots provided, if not, comment out
		do build_square_plots;
		//save plots to: './output/shapefiles/plots.shp' format: "shp"; // if new plots are created, comment out to save them
		
		// give plots a value for the distance to infrastructure (here distance to closest industry or road)
		ask plots { // only possible once industry and roads exist
			dist_to_infra  <- min(self distance_to (road closest_to(self)), self distance_to (industry closest_to(self))) ;
		}
		
		// assign plot to industry
		ask industry { // assign plots to industry
			my_plots_ind <- plots overlapping self;
		}
		// define the number of households according to the number of existing plots
		num_households <- int(length(plots where (each.assigned = false))/avg_nb_plots);
		create households number: num_households;
		create new_households;
		share_hungry <- length(households where(each.income/each.hh_size < each.min_income_hh))/length(households);
		
		// assign plots as farm plots to households
		loop while: (length(plots where(each.assigned = false)) > 0) {
			
			plots unassigned_plot <- one_of(plots where(each.assigned = false));

			plots neigh_plot <- one_of(neighbors_of(topology(plots), unassigned_plot, 10));
			households hh <- households where (one_of(each.my_plots) = neigh_plot);
			if (hh = nil) { 
				create households number: 1 {
					nb_plots <- 1;
					my_plots <- my_plots + unassigned_plot; // create one household with just this plot
				}
			}
			else {
				hh.my_plots <- hh.my_plots + unassigned_plot; 
				unassigned_plot.assigned <- true;
			}
		}
	}
	
	 // action that is called in init{} to build the plots of land 
	action build_square_plots {
		// comment out the following lines if building new plots
	    /*list<geometry> plots_list <- to_squares(shape, shape.width / 2);
	    loop while: (plots_list with_max_of each.area).area > max_plot_area {
	        geometry p <- (plots_list with_max_of each.area);
	        plots_list >> p;
	        plots_list <- plots_list + to_squares(p, p.width / 2);
	    }*/
	   
	    // create cells (cells are the smallest unit of land and belong to a plot); they can be bought off one plot and are then owned by another
	    create plains from: shape_plains;

	    // create plots and only keep plots that are in the plains
	    //create plots from: plots_list; // comment out line if building new plots
	    ask plots {
	    	if empty((plains) overlapping self) {
	    		do die;
	    	}	        
			
			//assign a random soil height, min = 0.5m
	        soil_height <-  rnd(0.5, max_soil_depth);
	        
	        // if swamp => soil height = 0
	        if !empty (swamp partially_overlapping self) {
	        	soil_height <- 0.0;
	        }
	        
	        //assign urban plots of land
	        if !empty (urban partially_overlapping self) {
	        	land_use <- 6;
	        	assigned <- true;
	        }
	        
	        //assign industrial plots of land
	        if !empty (industry partially_overlapping self) {
	        	land_use <- 7;
	        	assigned <- true;
	        	bought <- false;
	        }
	        
	        //give each plot its color, so that already color at t = 0
	        color_plot <- plot_colors[land_use -1];
    		color_plot_soil <- soil_colors[round(soil_height*2)];
	        loop i over: cells_list {
				i.col <- color_plot;
				i.soil_col <- color_plot_soil;
			}
   	 	}
		
	}

	// ENTIRE SECTION BELOW:  NECESSARY TO RUN FLOOD MODEL FROM GAMA AUTOMATICALLY
	// action to save cells as asc file to be input to flood model
	/*action save_cells {
			save cells to: '../EAT8a' + cycle + '/grid.asc' format: "asc";
	}
	
	
	// action to run flood model
	/*action run_caflood_after_dry {

	    // Step 1: Fix the ASC file using an external PowerShell script
	    string ps_script <- "C:\\Users\\amgraber\\Documents\\02_GAMMA2\\master_thesis\\EAT8a" + cycle + "\\fix_asc.ps1";
	    string ps_command <- "powershell -ExecutionPolicy Bypass -File \"" + ps_script + "\"";
	    empty_string <- command(ps_command);
	
	    // Step 2: Run CAFlood via PowerShell script
		string ps_caflood <- "C:\\Users\\amgraber\\Documents\\02_GAMMA2\\master_thesis\\EAT8a"+ cycle + "\\run_caflood.ps1";
		string caflood_command <- "powershell -ExecutionPolicy Bypass -File \"" + ps_caflood + "\"";
		empty_string <- command(caflood_command);
		
		string water_data_file <- "../EAT8a" + cycle + "/output/eat8a_WDraster_PEAK.asc";		
		water_data <- file(water_data_file);
		water_matrix <- matrix(water_data);
		empty_string <- nil;
	}*/
	
	// automatically runs every wet season
	reflex wet_season when:(season.current_season = WET) {
		//do save_cells; // save soil height asc file for flood model // NECESSARY FOR FLOOD MODEL, SO THAT CELL HEIGHT CHANGED ACCORDING TO ABM EVERY CYCLE
		//do run_caflood_after_dry; // run flood model
		ask cells overlapping geometry(plains) {
			do water_depth; // compute water depth for all cells
		}
		
		ask plots {
			do compute_water_depth; //compute water depth for plots based on water depth for cells
			}
		ask households {
			do do_rice;
		}
		ask plots {
			do generate_income_rice;
			do color_update;
		}
		ask households {
			do update_income;
			do clear_generated_income;
		}
	}
	
	// automatically runs every dry season 
	reflex dry_season when:(season.current_season = DRY) {
		ask industry {
			do new_ind;
		}
		ask plots {
			do compute_water_depth;
		}
		ask households {
			loop plottt over: copy(self.my_plots) {
				do do_dry_land_use plott: plottt;
				ask plottt {
					do generate_income_swamp;
					do generate_income_market;
					do generate_income_brick hh: myself;
					do generate_income_sold_plot;
				}
				do update_exp_income;
				do update_income;
				do clear_generated_income;
			}
		}
		tot_income <- households sum_of (each.income);
		ask new_households {
			do plain_pop_increase;
		}
		ask households {
			do sell_plot;
		}
		
		ask industry {
			do backfill_ind;
		}
		ask new_households {
			do backfill_hh;
		}
		tot_income_with_land <- households sum_of (each.income);
		ask households {do save_dry_income;}
		ask plots {do color_update;}
	}
	
	reflex when: season.current_season = WET {
		share_rice <- plots count (each.land_use = 1); // save share_rice during wet season
	}
	
	// reflex to save data in csv files during dry season
	reflex when: season.current_season = DRY { // for calibration: "when: cycle = 10", for sensitivity: "when: cycle = 16"
		share_urban <- plots count (each.land_use = 6);
		share_swamp <- plots count (each.land_use = 4);
		share_mg <- plots count (each.land_use = 2);
		share_bare <- plots count (each.land_use = 3);
		share_brick <- plots count (each.land_use = 5);
		
		share_hungry <- length(households where(each.income/each.hh_size < min_income))/length(households);
		save [cycle, simulation, max_soil_depth, base_price, likelihood_of_new_ind, price_param, mg_water_height, mg_necessary_ressources, brick_price_param, market_income, rice_income, avg_nb_plots, min_income, rate_pop_increase, tot_income, tot_income_with_land, share_hungry,plots count (each.land_use = 1), plots count (each.land_use = 2), plots count (each.land_use = 3),plots count (each.land_use = 4), plots count (each.land_use = 5), plots count (each.land_use = 6)] to: "../output/output_param/" + simulation+ ".csv" format: "csv";
		//save plots attributes: ["land_use", "soil_height"] to: ("../output/output_shp/plots_" + simulation + ".shp") crs: "EPSG:4326" format: "shp"; // can save plots to do flood model analysis
	}
	// make sure simulation stops at some point
	reflex when: cycle = 18 {
		ask simulations {
			do die;
		}
	}
}

// define seasons species
species seasons {
	int season_duration <- 1;// indicating six months 
	int shift_cycle <- season_duration * 2 update: season_duration * 2 + int(cycle - floor(season_duration / 2));
	int current_day <- 0 update:  cycle mod season_duration;
    int se <- 0 update: (shift_cycle div season_duration) mod 2;
    int shift_current_day <- 0 update: shift_cycle mod season_duration;
    int next_se <- 1 update: (se + 1) mod 2;                                      
	list<string> season_list <- [WET, DRY];
    map<string, list<float>> mean_water_map <- [WET::[1, 1, 1], DRY::[0.1,0.2,0.5]]; 
	string current_season <- DRY update: season_list[(cycle div season_duration) mod 2 ];
	float mean_water_surface_level <- 0.0 update: (rnd(mean_water_map[current_season][0],mean_water_map[current_season][1],mean_water_map[current_season][2]));
}

// Define households species
species households schedules: [] {
	int nb_plots min: 1;
	list<plots> my_plots <- [];
	float end_dry_season_income_for_plot;
	int hh_size <- int(gauss(4, 2)) min: 1; // household size with average at 4
	float min_income_hh <- hh_size * min_income;
	float income <- nb_plots*rice_income* (my_plots sum_of each.area_plot);
	float expected_income <- 0.0;
	
	init {
		
		// define number of plots for specific households
		if nb_plots !=1 {
			nb_plots <- int(gauss(3, 2)) ; // plot number per households randomly assigned with mean 3 and min 1 plot (normally distributed)
		}
		// assign one unassigned random plot as first plot
		plots my_first_plot <- one_of(plots where (each.assigned = false));
		my_first_plot.assigned <- true;
		my_plots <- my_plots + my_first_plot;
		if my_first_plot = nil {
			do die;
		}
		// if one plot assigned (control to not get error message)
		if nb_plots > 1 and my_first_plot != nil {
			loop while: length(my_plots)<nb_plots{
				plots additional_plot <- one_of(plots where(each distance_to first(my_plots)< max_dist_plots and each.assigned = false ));
				if additional_plot = nil {
					break;
				}
				additional_plot.assigned <- true;
				my_plots <- my_plots + additional_plot;
			}
		}
	}
		// do rice during wet season, if swamp or if water too high, remains swamp
		action do_rice {
   				self.income <- max(self.income - hh_size*min_income, 0);
   				self.expected_income <- self.income;
   				loop plot over: self.my_plots {
   					ask plot {
   						if land_use = 4 {
   							land_use <- 4; // swamp remains swamp
   						}
   						else if mean_water_depth <= 0.5 {
   							land_use <- 1; // rice
   						}
   						else {
   							land_use <- 4; // swamp
   						}
				}
   			}
      	}
      	
      	// choose land use during dry season
      	action do_dry_land_use (plots plott) {
      		if plott.land_use = 4 { // if swamp
      			if  self.expected_income < self.min_income_hh { // if income really necessary => sell land
	      					ask plott {
	      							offered_to_be_bought <- true;
	      							self.land_use <- 4; // swamp stays swamp
	      						}  
	      				}
	      		else if self.expected_income > min_income_hh and plott.mean_water_depth < mg_water_height { // if enough income => backfill and market gardening, in dry season mean_water_depth low enough (it's def higher than 0 because it's a swamp
		      				ask plott {
	      							land_use <- 2; // market gardening
	      						}
	      				}
	      		else { //if not enough income to backfill but sufficient income, sell plot
	      						ask plott {
	      							self.land_use <- 4; // swamp land (because low)
	      					} 
	      				}
      		}
      		else {
	      			if plott.soil_height = 0 { // mean water depth definitely positive in wet season => constantly under water in rainy season = swamp
	      				if  self.expected_income < self.min_income_hh { // if income really necessary => sell land
	      					ask plott {
	      							offered_to_be_bought <- true;
	      							self.land_use <- 4; // swamp because soil so low, def under water
	      						}  
	      				}
	      				else if self.expected_income > min_income_hh*mg_necessary_ressources and plott.mean_water_depth < mg_water_height { // if enough income => backfill and market gardening, in dry season mean_water_depth low enough
		      				ask plott {
	      							land_use <- 2; // market gardening
	      						}
	      				}
	      				else { //if not enough income to backfill but sufficient income, sell
	      						ask plott {
	      							offered_to_be_bought <- true;
	      							self.land_use <- 4; // swamp land (because low)
	      					} 
	      				}
	  				}
	      			else if plott.soil_height > 0 {
	      				if self.expected_income >= self.min_income_hh { // enough income
	      						if plott.mean_water_depth > 0 and plott.mean_water_depth < mg_water_height and self.expected_income > min_income_hh*mg_necessary_ressources {
	      							ask plott {
	      								self.land_use <- 2; // mg
	      							}
	      						}
	      						else if plott.mean_water_depth > 0  {
	      							ask plott {
	      								self.land_use <- 4; // swamp because under water
	      							}	
	      						}
	      						else  {
	      							ask plott {
	      								self.land_use <- 3; // bare land because not under water
	      							}	
	      						}
	      				}
	      				else { // not enough income yet
	      						ask plott {
	      							self.land_use <- 5; // BRICK // make bricks
	      						}
	      					}
	      				}
	      			}
	      		}
  		
		// sell plot if someone bought it => get income	  			
  		action sell_plot {
  			if my_plots != nil {
  				list<plots> sold_plots <- my_plots where (each.bought = true);
	  			if sold_plots != nil {
	  				loop i over: sold_plots {
	  					my_plots >> i;
	  					income <- income + i.price;
	  				}
	  				if my_plots = nil {
	  					do die;
	  				}
  				}
  			}
  		}			
  		
  		// action to update expected income after land use for one plot chosen
  		action update_exp_income {
			self.expected_income <- self.expected_income + sum_of(self.my_plots , each.income_generated + each.sold_income_generated);
		}
  		
  		// update actual income (without sold plots yet, since unsure if someone will buy)
		action update_income {
			self.income <- self.income + sum_of(self.my_plots , each.income_generated);
		}
		
		// save dry income for display experiment
		action save_dry_income {
			self.end_dry_season_income_for_plot <- self.income;
		}
		
		// clean generated income so that all plots are at value 0
		action clear_generated_income {
    		loop i over: my_plots {
    			i.income_generated <- 0.0;
    			i.sold_income_generated <- 0.0;
    		}
    	}
   }
 
 // define species of households that are new to the area
species new_households {
	plots home;
	bool homeless <- false;
	
	// all households try to buy one plot as a home (10 hh per plot)
	action plain_pop_increase {
		create new_households number:  ceil(num_households*rate_pop_increase/num_hh_per_plot){ // linear increase of plain pop, divided by 10 because one housing plot necessary per 10 households
			home <- (plots where (each.offered_to_be_bought = true)) with_min_of each.dist_to_infra;
			if home = nil {
				myself.homeless <- true;
			}
			else {
				ask home {
					bought <- true;
					offered_to_be_bought <- false;
				}
			}
		}
	}
	
	// backfill the plot
	action backfill_hh {
		if self.home != nil {
			if self.home.bought = true or self.home.land_use != 6 {
				if flip(0.2) {
					ask home {
					soil_height <- 0.5;
					land_use <- 6;
				}		
				
			}
			else {
					ask home {
					if mean_water_depth > 0 {
						land_use <- 4;
					}
					if land_use = 4 {
						land_use <- 4; // since it is the dry season, it might not be under water, but should still be considered a swamp since it si under water in wet season
					}
					else {
						land_use <- 3;
					}
			   }
			}
		}
	}
}
	
	// if household was unable to find home in previous cycle, looks for new plot and buys again
	reflex homeless {
		if homeless = true {
			home <- (plots where (each.offered_to_be_bought = true)) with_min_of each.dist_to_infra;
			if home = nil {
				self.homeless <- true;
			}
			else {
				ask home {
					myself.homeless <- false;
					bought <- true;
					offered_to_be_bought <- false;
				}
			}
		}
	}   
} 
	
	
// define plots species
species plots schedules: []{
	//Define attributes of plots 
	bool assigned;
	list<cells> cells_list <- cells where (self.shape covers each.location);
	rgb color_plot;
	rgb color_plot_soil;
	int land_use <- 1 min: 1 max: 7; //1: rice, 2: market gardening, 3:bare, 4: swamp, 5:brick making, 6: urban, 7: unassigned
	float soil_height  min: 0.0 max: 2.0; //soil height is a value between 0m and 2m 
	float dist_to_infra min: 0.1;
	float price <- length(self.cells_list)*25 *(price_param*exp(1/(dist_to_infra+1)) + base_price); // only thing per meter squared, not ha
	bool offered_to_be_bought <- false; 
	bool bought <- false; // turns true if someone buys it and false again at the beginning of the next season
	float area_plot <-   0.2;// get area in hectares (each cell 25m2)length(cells_list)*25/10000
	float income_generated;
	float sold_income_generated;
	float mean_water_depth;
	float max_water_depth;
	
	aspect default {
		draw shape color: color_plot;
	}
	
	action compute_water_depth {
    	self.bought <- false;
    	self.offered_to_be_bought <- false;
    	ask seasons {
    		myself.mean_water_depth <- self.mean_water_surface_level - myself.soil_height;
       	}
    	self.max_water_depth <- mean_of (cells_list, each.water_depth);
    }
	
	// generate income for rice during wet season
	action generate_income_rice {
      		if self.land_use = 1 {
      			self.income_generated <- self.area_plot * rice_income;
      			if self.max_water_depth >= 2 {
      				self.income_generated <- 0.0;
      			}
      			else if self.max_water_depth > 1 and self.max_water_depth < 2 {
      				self.income_generated <- self.income_generated * 0.9;
      			}
      			else if self.max_water_depth <= 1 and self.max_water_depth > 0.5 {
      				self.income_generated <- self.income_generated * 0.5;
      			}
      			else if self.max_water_depth <= 0.5 {
      				self.income_generated <- self.income_generated * 0.3;
      			}
      		}
      	}
    
    // generate income for market gardening 	
    action generate_income_market {
      		if self.land_use = 2 {
      			self.income_generated <- self.area_plot * market_income;
      		}
      	}
    
    // generate income from swamp, ratio compared to rice income based on Brouillet et al. (2025)  	
    action generate_income_swamp {
      		if self.land_use = 4 {
      			self.income_generated <- self.area_plot * rice_income * (1.9/3.1);
      		}
      	}
     
      // generate income from selling a plot  	
     action generate_income_sold_plot {
      		if self.offered_to_be_bought = true {
      			self.sold_income_generated <- self.price;
      		}
      	}
    
     // generate income from brick making => make as many bricks until income covered	
    action generate_income_brick (households hh)  {
    	if self.land_use = 5 { /*and self.offered_to_be_bought = false {*/
    		if (hh.min_income_hh - hh.income)>0 { // if bricks done for income => remove what's needed
    			float brick_price_s <- (brick_price - dist_to_infra*brick_price_param) > 25? (brick_price - dist_to_infra*brick_price_param):25 ;
    			float depth_bricked <- ( hh.min_income_hh - hh.income) / (self.area_plot * 10000 * 1000 * brick_price_s); //area plot in ha, to m2 => *10000, *1000 for 1000 bricks per m3
    			depth_bricked <- max(depth_bricked, 0.1); //AT LEAST 0.3m bricked => cover more than needs
		      	float soil_layers_bricked <- min(depth_bricked, self.soil_height);
				self.soil_height <- self.soil_height - soil_layers_bricked;
				float brick_income <- self.area_plot * 1000 *brick_price_s * soil_layers_bricked; // Volume * number bricks * price per brick
				self.income_generated <- brick_income;
				if self.income_generated < (hh.min_income_hh - hh.income) {
					self.offered_to_be_bought <- true; // sell if brick making does not yield enough income
				}
    		}
    	}
    }    
    
    // update color at the end of each cylce
    action color_update {
    	color_plot <- plot_colors[land_use -1];
    	color_plot_soil <- soil_colors[round(soil_height*2)];
    	
	        loop i over: cells_list {
				i.col <- color_plot;
				i.soil_col <- color_plot_soil;
				i.height <- soil_height;
			}
    }
}

// define elevation grid, necessary for flood model
grid elevation file: dem_file {
}

// define grid "cells" as part of a plot, initially done like this in case fragmentation of plots should be added to model
grid cells cell_width: 5 cell_height: 5 {
	float height;
	rgb col;
	rgb soil_col;
	float water_depth;
	list<elevation> elevation_grid_cells;
	
	//only necessary for flood model, defines cell height for exported dem
	init {
		elevation_grid_cells <- elevation where (self.shape covers each.location);
		grid_value <- elevation_grid_cells mean_of each.grid_value;
	}
	
	reflex update_grid {
		grid_value <- height != nil? height:grid_value ; // if in plains height = soil_height of plot, otherwise grid_value remains, which was taken from dem file
	}
	
	action water_depth {
		water_depth <- water_depths_list[cycle];
	}
	
	aspect default {
		draw shape color: col;
	}
	aspect soil {
		draw shape color: soil_col;
	}

}


// define species industry
species industry {
	float wanted_area <- rnd(3*max_plot_area, 10*max_plot_area)/10000; // area in ha
	list<plots> my_plots_ind <- [];
	plots first_plot;
	
	action new_ind {
		if flip(likelihood_of_new_ind) {
			create industry number: 1 {
				first_plot <- plots closest_to any(industry);
				loop while: first_plot = nil {
					first_plot <- plots closest_to any(road);
				}
				ask first_plot {
					self.assigned <- true;
					self.bought <- true;
				}
				my_plots_ind <- my_plots_ind + first_plot;
				loop while: my_plots_ind sum_of (each.area_plot) < wanted_area { // all area indications should be in ha
					plots add_plot <- one_of(agents_touching(first_plot));
					ask add_plot {
						self.assigned <- true;
						self.bought <- true;
					}
					my_plots_ind <- my_plots_ind + add_plot;
				}
			}
		}
	}
	
	action backfill_ind {
		if my_plots_ind != nil and my_plots_ind != [] {
		if one_of(my_plots_ind).bought = true {
			loop i over: my_plots_ind {
				if i != nil {
					i.land_use <- 7;
					i.soil_height <-  max_soil_depth;
					i.bought <- false;
				}
			}
		}
	}	
	}
	
	aspect default {
		draw shape color: #black;
	}
}

//define irrigation channels, has to be a species but does not act as an agent
species irr {
	aspect default {
		draw shape color: #lightblue;
	}
}

//define rivers, has to be a species but does not act as an agent
species river {
	aspect default {
		draw shape color: #darkblue;
	}
}

//define roads, has to be a species but does not act as an agent
species road {
	aspect default {
		draw shape color: #gray;
	}
}

//define plains area, has to be a species but does not act as an agent
species plains {
	aspect default {
		draw shape color: #green;
	}
}

//define swamp area and urban area for initialization, has to be a species but does not act as an agent
species swamp {}
species urban {}

// solely for display purposes
experiment display_experiment type: gui {

	output{
		// show land use
		display land_display {
			species cells aspect: default;
			species irr aspect: default;
			species river aspect: default;
			species road aspect: default;
			species industry aspect: default;
		}
		
		// show soil_height
		display soil {
			species cells aspect: soil;
		}
		
		// show share of each land use
		display Landuse_Share refresh: season.current_season = WET {
			chart "Dry Season Landuse" type: pie{
				data "market" value:  plots count (each.land_use = 2) color: #darkgreen;
				data "bare" value: plots count (each.land_use = 3) color: #brown;
				data "swamp" value: plots count (each.land_use = 4) color: #blue;
				data "brick" value: plots count (each.land_use = 5) color: #orange;
				data "urban" value: plots count (each.land_use = 6) color: #grey;

				}	
			}
		}
	}
	
// experiment to determine the number of runs necessary to account for stochasticity by running the model until the variance of chosen variables stabilizes
//here: varied parameter sets widely to see if the result is the same, repeated many times to see when variance stabilizes
experiment nb_runs_necessary type: batch repeat: 50 until: cycle = 11 parallel: false  {
	
	method exploration sample:20 sampling: "latinhypercube";
	
	parameter "Maximum Soil Depth" var: max_soil_depth min: 1.20 max: 2.0 unit: "m" ;
	parameter "Land price" var: base_price min: 5000.0 max: 30000.0 unit: "ariary" ;
	parameter "Price parameter for calibration" var: price_param among: [1000.0, 5000, 10000, 20000, 30000] unit:"no unit";
	parameter "market income" var: market_income min: 1600000 max:15000000  unit:"Ariary"  ;
	parameter "rice income" var: rice_income min: 4241281 max:10737420 unit: "Ariary"; 
	parameter "number of plots" var: avg_nb_plots min: 3 max: 5 unit:"number of plots" ;
	parameter "min income" var: min_income min: 821370.0 max: 2000000.0 unit: "ariary" ;
	parameter "pop increase rate" var: rate_pop_increase min: 0.001 max: 0.0508 unit: "percentage";
	parameter "Likelihood of new Industry" var: likelihood_of_new_ind min: 0.0 max: 0.5 unit: "no unit" ;
	parameter "Water height max for market gardening" var: mg_water_height min: 0.51 max: 1.0 unit: "m" ;
	parameter "Parameter to vary brick price" var: brick_price_param min: 0.001 max: 0.1 unit: "no unit";
	parameter "Ressources necessary for market gardening" var: mg_necessary_ressources min: 1.0 max: 2.0 unit: "no unit" ;
		
}	
	
// experiment for calibration:choose flood depths at top of model for 2017 to 2022 and choose north polder data in 2017 at the top in the global species
experiment calibration_experiment type: batch repeat: 1 until: cycle = 11 parallel: false keep_seed:true {

	method exploration sample:30 sampling: "latinhypercube";
	
	parameter "Maximum Soil Depth" var: max_soil_depth min: 1.20 max: 2.0 unit: "m" ;
	parameter "Land price" var: base_price min: 5000.0 max: 30000.0 unit: "ariary" ;
	parameter "Price parameter for calibration" var: price_param among: [1000.0, 5000, 10000, 20000, 30000] unit:"no unit";
	parameter "market income" var: market_income min: 1600000.0 max:15000000.0  unit:"Ariary"  ;
	parameter "rice income" var: rice_income min: 4241281.0 max:10737420.0 unit: "Ariary"; 
	parameter "number of plots" var: avg_nb_plots min: 3 max: 5 unit:"number of plots" ;
	parameter "min income" var: min_income min: 500000.0 max: 1500000.0 unit: "ariary" ;
	parameter "pop increase rate" var: rate_pop_increase min: 0.001 max: 0.0508 unit: "percentage";
	parameter "Likelihood of new Industry" var: likelihood_of_new_ind min: 0.0 max: 0.5 unit: "no unit" ;
	parameter "Water height max for market gardening" var: mg_water_height min: 0.51 max: 1.0 unit: "m" ;
	parameter "Parameter to vary brick price" var: brick_price_param min: 0.001 max: 0.1 unit: "no unit";
	parameter "Ressources necessary for market gardening" var: mg_necessary_ressources min: 1.0 max: 2.0 unit: "no unit" ;

}

// experiment for calibration:choose flood depths at top of model for 2017 to 2022 and change data to east polder in 2017 at the top in the global species
experiment validation_experiment type: batch repeat: 10 until: cycle = 11 parallel: false { 
	method exploration sample:0 sampling: "uniform";
}	

//sensitivity analysis: choose flood depth at top of model for 2022 to 2030 and north polder data in 2022
experiment sensitivity_experiment type: batch until: cycle = 18 parallel: false  {

	method "morris" outputs:["num_hh_income", "tot_income"]
	sample:20 levels: 4 report: "../output/morris.txt" results: "../output/morris_raw.csv";
	
	parameter "Land price" var: base_price among: [17551.47, 21939.34, 26327.21];
	parameter "market income" var: market_income among: [8873791.0, 11092238.0, 13310686.0] ;
	parameter "rice income" var: rice_income among: [7321251.0,  9151563.0,  10981876.0]; 
	parameter "min income" var: min_income among: [415232.4, 519040.5, 622848.6];
	parameter "pop increase rate" var: rate_pop_increase among: [0.00991251, 0.01239064, 0.01486876];
}	
	
// experiment to run the trajectories: choose flood depth at top of model for 2022 to 2030 and north polder data in 2022
experiment trajectory_experiment type: batch repeat: 10 until: cycle = 18 parallel: false { // repeat each parameter set 10 times, until 18 cycles
	method exploration sample:5 sampling: "latinhypercube";
	//parameter "min income" var: min_income among: among: [415232.4, 519040.5, 622848.6]; //  vary min income since important one identified in boxplots
	parameter "pop increase rate" var: rate_pop_increase min: 0.0001 max: 0.1 unit: "percentage"; //  vary pop increase rate since important one identified in morris analysis
	
}
	
	

