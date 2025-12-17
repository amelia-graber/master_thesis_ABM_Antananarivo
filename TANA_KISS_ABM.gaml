/**
* Name: TANA KISS ABM
* Author: Amélia Graber
*/

model TanaKiss

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
	float max_plot_area <- 20.0; // area per farming plot, all same size, here: fictive value chosen to have enough plots in model
	float max_soil_depth <- 1.2016519; // maximum soil depth (soil_depth at t = 0 for some randomly chosen farming plots)
	float base_price <- 15176.6; // price of land  (constant for all plots)
	float market_income <- 14700260.0; // income (ariary) from market gardening for one season on 1 ha
	float rice_income <- 7375592.0; // income (ariary) from rice making for one season on 1 ha
	float mg_water_height <- 0.9871901; // maximum water height for market gardening to be possible (if water higher => swamp)
	float brick_price <- 75.0; // price of one brick in ariary
	
	// tracking variables
	int share_urban <- plots count (each.land_use = 6); // variable to track number of plots urban
	int share_swamp <- plots count (each.land_use = 4); // variable to track number of plots swamp
	int share_mg <- plots count (each.land_use = 2); // variable to track number of plots market gardening
	int share_bare <- plots count (each.land_use = 3); // variable to track number of plots bare
	int share_brick <- plots count (each.land_use = 5); // variable to track number of plots brick
	int share_rice <- plots count(each.land_use = 1); // variable to track number of plots rice
	float share_hungry; // the share of households lacking enough income (below min_income per person)
	int num_hh_income; // number of households gaining income from the land
	float tot_income; // total income for all households in the polder, before selling the land
	float tot_income_with_land; // total income for all households in the polder, after selling the land
	
	// households attributes
	int num_households; // Variable to save how many households exist (defined according to the number of farming plots)
	int avg_nb_plots <- 4; // average number of plots per household
	float max_dist_plots <- 3000.0; // max distance between plots of one household 
	float min_income <- 1618067.0; // minimum income per household member for food subsistence
	float rate_pop_increase <- 0.04220062;// rate of population increase in the plains
	float mg_necessary_ressources <- 1.2152479; // factor of minimum income per household necessary for market gardening (needs ressources)
	int num_hh_per_plot <- 10; // number of households finding housing on one plot
	
	// industry attributes
	float likelihood_of_new_ind <- 0.2214051; // likelihood of new ind every year
	
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
		
		//create plots of land 
		do build_square_plots;
		
		// assign one plot to be industrial
		loop times: 1 {
			ask one_of(plots) {
        	land_use <- 7;
        	assigned <- true; // so that it can't be assigned to someone else
        	bought <- false; 
       		 }
		
		}   
		
		// assign plot to industry
		ask industry { // assign plots to industry
			my_plots_ind <- plots where(each.land_use = 7);
		}    
        
		// give plots a value for the distance to infrastructure (here distance to industry)
		ask plots{ // only possible once industry exists
			dist_to_infra  <- self distance_to one_of(plots where (each.land_use = 7))*100 ;
			
		}
		
		// add urban plots as close to industry as possible (188 = 18.8% of North Polder is urban in 2022)
		loop times: 188 {
			list<plots> plots_unassigned <- plots where (each.assigned = false);
			ask (plots_unassigned  with_min_of (each.dist_to_infra)) {//with_min_of each.dist_to_infra {
				land_use <- 6;
				assigned <- true;
			}
		}
		
		// give plots colors for display
		ask plots {
			color_plot <- plot_colors[land_use -1];
		    color_plot_soil <- soil_colors[round(soil_height*2)];
			ask cells where (self.shape covers each.location) {
				col <- myself.color_plot;
				soil_col <- myself.color_plot_soil;
			}
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
	    list<geometry> plots_list <- to_squares(shape, shape.width / 2);
	    loop while: (plots_list with_max_of each.area).area > max_plot_area {
	        geometry p <- (plots_list with_max_of each.area);
	        plots_list >> p;
	        plots_list <- plots_list + to_squares(p, p.width / 2);
	    }
	        
        create plots from: plots_list {
        	 soil_height <-  rnd(0.5, max_soil_depth); // randomly vary soil heigh between 0.5m and the max_soil_depth calibrated
        
		        if flip(0.25) { // 25% swamp
		        	soil_height <- 0.0;
		        }
		        
				assigned <- false; // so that they can be assigned
			    
			    // give plots initial colors
		        color_plot <- plot_colors[land_use -1];
	    		color_plot_soil <- soil_colors[round(soil_height*2)];
		        loop i over: cells_list {
					i.col <- color_plot;
					i.soil_col <- color_plot_soil;
				}
		   	 }
	       }
	

	
	
	// automatically runs every wet season
	reflex wet_season when:(season.current_season = WET) {
		ask cells{
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
				tot_income <- households sum_of each.income;
				do clear_generated_income;
			}
		}
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
		tot_income_with_land <- households sum_of(each.income);
		ask households {do save_dry_income;}
		ask plots {do color_update;}
	}
	
	
	reflex when: season.current_season = WET {
		share_rice <- plots count (each.land_use = 1); // save share_rice during wet season
	}
	// reflex to save data in csv files during dry season
	reflex when: season.current_season = DRY { // for calibration: "when: cycle = 10", for sensitivity: "when: cycle = 16"
		// update data
		share_urban <- plots count (each.land_use = 6);
		share_swamp <- plots count (each.land_use = 4);
		share_mg <- plots count (each.land_use = 2);
		share_bare <- plots count (each.land_use = 3);
		share_brick <- plots count (each.land_use = 5);
		share_hungry <- length(households where(each.income/each.hh_size < min_income))/length(households);
		num_hh_income <- length(households);
		
		// save data
		save [cycle, simulation, rate_pop_increase, min_income, base_price, market_income, rice_income, length(households where(each.income/each.hh_size < min_income))/length(households), tot_income ,tot_income_with_land, share_rice, plots count (each.land_use = 2), plots count (each.land_use = 3),plots count (each.land_use = 4), plots count (each.land_use = 5), plots count (each.land_use = 6)] to: "../output/output_param/" + simulation+ cycle+".csv" format: "csv";
	}
	
	// make sure simulation stops at some point
	reflex when: cycle = 17 {
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
    map<string, list<float>> mean_water_map <- [WET::[1, 1, 1], DRY::[0.1,0.2,0.3]]; // these are the mean water depths, randomly chosen from list, uniform for all of plains
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
		my_first_plot.assigned <- true; // make sure not assigned to anyone else
		my_plots <- my_plots + my_first_plot; // keep in list of each household
		if my_first_plot = nil { // control to not get error message
			do die;
		}
		
		// if one plot assigned (control to not get error message)
		if nb_plots > 1 and my_first_plot != nil {
			loop while: length(my_plots)<nb_plots{ // add plot until nb_plots reached
				plots additional_plot <- one_of(plots where(each distance_to first(my_plots)< max_dist_plots and each.assigned = false ));
				if additional_plot = nil {
					break;
				}
				additional_plot.assigned <- true; // make sure not assigned to anyone else
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
	      							self.land_use <- 4; //  swamp because soil so low, definitely under water
	      					} 
	      				}
      		}
      		else {
	      			if plott.soil_height = 0 { // mean water depth definitely positive in wet season => constantly under water in rainy season = swamp
	      				if  self.expected_income < self.min_income_hh { // if income really necessary => sell land
	      					ask plott {
	      							offered_to_be_bought <- true;
	      							self.land_use <- 4; // swamp because soil so low, definitely under water
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
	      								self.land_use <- 2; // market gardening
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
	      							self.land_use <- 5; // make bricks
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
					if land_use = 4 {
						land_use <- 4;
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
	bool assigned <- false;
	list<cells> cells_list <- cells where (self.shape covers each.location);
	rgb color_plot;
	rgb color_plot_soil;
	int land_use <- 1 min: 1 max: 7; //1: rice, 2: market gardening, 3:bare, 4: swamp, 5:brick making, 6: urban, 7: unassigned
	float soil_height  min: 0.0 max: 2.0; //soil height is a value between 0m and 2m 
	float dist_to_infra min: 0.1;
	float price <- base_price*100; 
	bool offered_to_be_bought <- false; 
	bool bought <- false; // turns true if someone buys it and false again at the beginning of the next season
	float area_plot <-   1.0;// get area in hectares (each cell 25m2)length(cells_list)*25/10000
	float income_generated;
	float sold_income_generated;
	float mean_water_depth;
	float max_water_depth;
	
	aspect default {
		draw shape color: color_plot;
	}
	
	// compute water depth
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
    			float brick_price_s <- brick_price ;
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

// define grid "cells" as part of a plot, initially done like this in case fragmentation of plots should be added to model
grid cells cell_width: 5 cell_height: 5 {
	float height;
	rgb col;
	rgb soil_col;
	float water_depth;

	
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
	float wanted_area <- 1.0; // area in ha
	list<plots> my_plots_ind <- [];
	plots first_plot;
	
	action new_ind {
		if flip(likelihood_of_new_ind) {
			create industry number: 1 {
				first_plot <- plots closest_to any(industry);
				loop while: first_plot = nil {
					first_plot <- plots  with_min_of each.dist_to_infra;
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

// solely for display purposes
experiment display_experiment type: gui {
	output{
		// show land use
		display land_display {
			species cells aspect: default;
			species industry aspect: default;
		}
		// show soil_height
		display soil {
			species cells aspect: soil;
		}
		
		// show share of each land use
		display Landuse_Share refresh: season.current_season = WET {
			chart "Dry Season Landuse" type: pie{
				data "market" value: plots count (each.land_use = 2) color: #darkgreen;
				data "bare" value: plots count (each.land_use = 3) color: #brown;
				data "swamp" value: plots count (each.land_use = 4) color: #blue;
				data "brick" value: plots count (each.land_use = 5) color: #orange;
				data "urban" value: plots count (each.land_use = 6) color: #grey;
			}
		}
		
		// show distribution of income per household
		display income refresh: season.current_season = DRY {
			chart "Income per Household (Mio. Ariary)" type: histogram {
				datalist (distribution_of(households collect (each.end_dry_season_income_for_plot/1000000),8,0, 200) at "legend")
				value:(distribution_of(households collect (each.end_dry_season_income_for_plot/1000000), 8, 0, 200) at "values");
			}
		}
	}
}

// experiment for calibration:choose flood depths at top of model for 2017 to 2022
experiment calibration_experiment type: batch repeat: 10 until: cycle = 11 parallel: false { 
	method exploration sample:30 sampling: "latinhypercube";
	
	parameter "pop increase rate" var: rate_pop_increase min: 0.001 max: 0.0508 unit: "percentage";
	parameter "Maximum Soil Depth" var: max_soil_depth min: 1.20 max: 2.0 unit: "m" ;
	parameter "Land price" var: base_price min: 5000.0 max: 30000.0 unit: "ariary" ;
	parameter "market income" var: market_income min: 1600000.0 max:15000000.0  unit:"Ariary"  ;
	parameter "rice income" var: rice_income min: 4241281.0 max:10737420.0 unit: "Ariary"; 
	parameter "number of plots" var: avg_nb_plots min: 3 max: 5 unit:"number of plots" ;
	parameter "min income" var: min_income min: 821370.0 max: 2000000.0 unit: "ariary" ;
	parameter "Likelihood of new Industry" var: likelihood_of_new_ind min: 0.0 max: 0.5 unit: "no unit" ;
	parameter "Water height max for market gardening" var: mg_water_height min: 0.51 max: 1.0 unit: "m" ;
	parameter "Ressources necessary for market gardening" var: mg_necessary_ressources min: 1.0 max: 2.0 unit: "no unit" ;
}

// experiment for calibration:choose flood depths at top of model for 2017 to 2022, change the share of urban area in 2017 = 34% (l. 109), and swamp: 7% (l.166)
experiment validation_experiment type: batch repeat: 10 until: cycle = 11 parallel: false { 
	method exploration sample:0 sampling: "uniform";
}

// experiment to run the trajectories: choose flood depth at top of model for 2022 to 2030
experiment trajectory_experiment type: batch repeat: 10 until: cycle = 18 parallel: false { // repeat each parameter set 10 times, until 18 cycles
	method exploration sample:5 sampling: "latinhypercube";
	//parameter "min income" var: min_income among: [1294453.0, 1618067.0, 1941680.0];
	parameter "pop increase rate" var: rate_pop_increase min: 0.0001 max: 0.1 unit: "percentage"; // only vary pop increase rate since important one identified in sensitivity analysis
	
}

// sensitivity analysis: choose flood depth at top of model for 2022 to 2030
experiment sensitivity_experiment type: batch until: cycle = 18 parallel: false {
	method "morris" outputs:["num_hh_income", "tot_income"]
	sample:20 levels: 4 report: "../output/morris.txt" results: "../output/morris_raw.csv";
	
	parameter "Land price" var: base_price among: [12141.28, 15176.60, 18211.92];
	parameter "market income" var: market_income among: [11760208.0, 14700260.0, 17640313.0] ;
	parameter "rice income" var: rice_income among: [5900474.0,  7375592.0,  8850711.0]; 
	parameter "min income" var: min_income among: [1294453.0, 1618067.0, 1941680.0];
	parameter "pop increase rate" var: rate_pop_increase among: [0.03376050, 0.04220062, 0.05064075];
}