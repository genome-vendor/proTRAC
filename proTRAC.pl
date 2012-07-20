#!/usr/bin/perl -w
use Cwd;
use GD;
use Time::HiRes qw(gettimeofday);
use Tk;
use Tk::BrowseEntry;
use Tk::JPEG;
use Tk::Pane;
use Tk::StayOnTop;
use Tk::widgets qw/JPEG PNG/;

###   GENERAL SETTINGS   ###
$minimum_size_per_cluster=100;
$maximum_size_per_cluster=1000000;
$consider_only_unique_mappers=0;
$directionality_threshold=75;
$do_monodirectional=1;
$do_bidirectional=1;
$do_nondirectional=1;
$desired_length_minimum=26;
$desired_length_maximum=32;
$min_loci_per_read=1;
$max_loci_per_read='';
$frequently_threshold=5;
$do_reconsideration=1;

###   SIMPLE SETTINGS   ###
$minimum_piRNA_loci_per_cluster=2;
$minimum_normalized_reads=0;
$minimum_unique_mappers=0;
$minimum_piRNAdensity_per_cluster_entry=0.1;
$minimum_U_loci=0;
$minimum_10A_loci=0;
$minimum_desired_length_loci=0;

###   PROBABILISTIC SETTINGS   ###
$significance_piRNA_density=0.01;
$minimum_strand_bias=2;
$minimum_enrichment_for_rare_loci=2;
$minimum_enrichment_for_loci_with_optimal_length=2;
$minimum_enrichment_for_1T_OR_10_A_loci=2;
$assume_random_basecomposition=0;

###   OUTPUT   ###
$do_visualization=1;
$picture_width=560;
$picture_height=220;
$accent_multiple_mappers=1;
$indicate_transcription_rate=0;
$normalize_multiple_mappers=0;
$pixel_for_one_transcript=3;
$output_summary=1;
$sort_summary_by_score=0;
$calculate_average_transcription=0;
$output_clustered=0;
$transcription_cutoff_all='';
$output_clustered_unique=0;
$transcription_cutoff_unique='';
$output_clustered_multi=0;
$transcription_cutoff_multi='';

###   GUI   ###
# main window
$MAIN_WINDOW=MainWindow->new(-title=>"proTRAC",-background=>White);
$MAIN_WINDOW->geometry("1024x786");
$MAIN_WINDOW->protocol('WM_DELETE_WINDOW',sub{unlink"prev_temp";if($directory_former_session){unlink"$directory_former_session/temp_stat";}exit;});
$mw=$MAIN_WINDOW->Scrolled('Pane',-scrollbars=>'osoe',-background=>White,-sticky=>'nw',-gridded=>'y')->pack(-fill=>'both',-expand=>1);
$cwd=getcwd;
$programfiles=$cwd."/proTRAC_files";
$background=$mw->Photo(-format=>'png',-file=>"$programfiles/gui");
$mw->Label(-image=>$background)->pack();

# input
$filetypes = [['ELAND3 files', '.txt'],['All Files',   '*'],];
$input_file_name="select your input file (ELAND3)";
$entry_input_file=$mw->Entry(-width=>35,-font=>"Arial 8",-textvariable=>\$input_file_name)->place(-height=>20,-x=>10,-y=>93);
$browse=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/browse");
$button_browse_input_file=$mw->Button(-image=>$browse,-background=>White,-command=>sub{$input_file_name=$mw->getOpenFile(-filetypes=>$filetypes,-defaultextension=>'.txt');})->place(-width=>43,-height=>38,-x=>235,-y=>83);
$fasta_eq_occ_variable="NO";
$fasta_eq_occ=$mw->BrowseEntry(-variable=>\$fasta_eq_occ_variable,-font=>"Arial 7",-width=>4,-listwidth=>14,-listheight=>2,-state=>'readonly',-command=>\&state)->place(-x=>235,-y=>131);
$fasta_eq_occ->insert('end',"YES","NO");
sub state
	{
	if($fasta_eq_occ_variable eq "YES")
		{
		$mw->messageBox(-message=>"Using this option, proTRAC will not run proper if probe_id\nin ELAND3 file does not refer to sequence frequency.",-type=>'ok',-icon=>'info');
		if($transcription_cutoff_all eq""){$transcription_cutoff_all=1;}
		if($transcription_cutoff_unique eq""){$transcription_cutoff_unique=1;}
		if($transcription_cutoff_multi eq""){$transcription_cutoff_multi=1;}
		$cb_normalize->configure(-background=>White,-state=>'normal');
		$cb_indicate->configure(-background=>White,-state=>'normal');
		$entry_pixel->configure(-background=>White,-state=>'normal');
		$cb_average->configure(-background=>White,-state=>'normal');
		$entry_cutoff_all->configure(-background=>White,-state=>'normal');
		$entry_cutoff_unique->configure(-background=>White,-state=>'normal');
		$entry_cutoff_multi->configure(-background=>White,-state=>'normal');
		}
	elsif($fasta_eq_occ_variable eq "NO")
		{
		$calculate_average_transcription=0;
		$normalize_multiple_mappers=0;
		$indicate_transcription_rate=0;
		$transcription_cutoff_all='';
		$transcription_cutoff_unique='';
		$transcription_cutoff_multi='';
		$cb_normalize->configure(-background=>grey90,-state=>'disabled');
		$cb_indicate->configure(-background=>grey90,-state=>'disabled');
		$entry_pixel->configure(-background=>grey90,-state=>'disabled');
		$cb_average->configure(-background=>grey90,-state=>'disabled');
		$entry_cutoff_all->configure(-background=>grey90,-state=>'disabled');
		$entry_cutoff_unique->configure(-background=>grey90,-state=>'disabled');
		$entry_cutoff_multi->configure(-background=>grey90,-state=>'disabled');
		}
	}

# general settings
$general1=$mw->Entry(-width=>8,-font=>"Arial 8",-justify=>'right',-textvariable=>\$minimum_size_per_cluster)->place(-height=>14,-x=>228,-y=>186);
$general2=$mw->Entry(-width=>8,-font=>"Arial 8",-justify=>'right',-textvariable=>\$maximum_size_per_cluster)->place(-height=>14,-x=>228,-y=>206);
$general3=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$consider_only_unique_mappers,-command=>sub{if($consider_only_unique_mappers==1){$simple2->configure(-textvariable=>\$minimum_piRNA_loci_per_cluster);$simple3->configure(-textvariable=>\$minimum_piRNA_loci_per_cluster);}else{$simple2->configure(-textvariable=>\$minimum_normalized_reads);$simple3->configure(-textvariable=>\$minimum_unique_mappers);}})->place(-height=>14,-width=>26,-x=>228,-y=>225);
$general4=$mw->Entry(-width=>3,-font=>"Arial 8",-justify=>'right',-textvariable=>\$directionality_threshold)->place(-height=>14,-x=>228,-y=>244);	
$general5=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$do_monodirectional)->place(-height=>14,-width=>26,-x=>228,-y=>262);
$general6=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$do_bidirectional)->place(-height=>14,-width=>26,-x=>228,-y=>282);
$general7=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$do_nondirectional)->place(-height=>14,-width=>26,-x=>228,-y=>301);
$general8=$mw->Entry(-width=>3,-font=>"Arial 8",-justify=>'right',-textvariable=>\$desired_length_minimum)->place(-height=>14,-x=>228,-y=>321);
$general9=$mw->Entry(-width=>3,-font=>"Arial 8",-justify=>'right',-textvariable=>\$desired_length_maximum)->place(-height=>14,-x=>258,-y=>321);
$general10=$mw->Entry(-width=>3,-font=>"Arial 8",-justify=>'right',-textvariable=>\$min_loci_per_read)->place(-height=>14,-x=>228,-y=>340);
$general11=$mw->Entry(-width=>3,-font=>"Arial 8",-justify=>'right',-textvariable=>\$max_loci_per_read)->place(-height=>14,-x=>258,-y=>340);
$general12=$mw->Entry(-width=>3,-font=>"Arial 8",-justify=>'right',-textvariable=>\$frequently_threshold)->place(-height=>14,-x=>228,-y=>359);
$general13=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$do_reconsideration,-command=>sub{if($do_reconsideration==1){$general12->configure(-state=>'normal');}else{$general12->configure(-state=>'disabled');}})->place(-height=>14,-x=>258,-y=>359);

# simple settings
$simple1=$mw->Entry(-width=>4,-font=>"Arial 8",-justify=>'right',-textvariable=>\$minimum_piRNA_loci_per_cluster)->place(-height=>14,-x=>228,-y=>416);
$simple2=$mw->Entry(-width=>4,-font=>"Arial 8",-justify=>'right',-textvariable=>\$minimum_normalized_reads)->place(-height=>14,-x=>228,-y=>435);
$simple3=$mw->Entry(-width=>4,-font=>"Arial 8",-justify=>'right',-textvariable=>\$minimum_unique_mappers)->place(-height=>14,-x=>228,-y=>455);
$simple4=$mw->Entry(-width=>4,-font=>"Arial 8",-justify=>'right',-textvariable=>\$minimum_piRNAdensity_per_cluster_entry)->place(-height=>14,-x=>228,-y=>474);
$simple5=$mw->Entry(-width=>4,-font=>"Arial 8",-justify=>'right',-textvariable=>\$minimum_U_loci)->place(-height=>14,-x=>228,-y=>494);
$simple6=$mw->Entry(-width=>4,-font=>"Arial 8",-justify=>'right',-textvariable=>\$minimum_10A_loci)->place(-height=>14,-x=>228,-y=>513);
$simple7=$mw->Entry(-width=>4,-font=>"Arial 8",-justify=>'right',-textvariable=>\$minimum_desired_length_loci)->place(-height=>14,-x=>228,-y=>533);

# probabilistic settings
$prob_set1=$mw->Entry(-width=>5,-font=>"Arial 8",-justify=>'right',-textvariable=>\$significance_piRNA_density)->place(-height=>14,-x=>228,-y=>591);
$prob_set2=$mw->Entry(-width=>5,-font=>"Arial 8",-justify=>'right',-textvariable=>\$minimum_strand_bias)->place(-height=>14,-x=>228,-y=>610);
$prob_set3=$mw->Entry(-width=>5,-font=>"Arial 8",-justify=>'right',-textvariable=>\$minimum_enrichment_for_rare_loci)->place(-height=>14,-x=>228,-y=>630);
$prob_set4=$mw->Entry(-width=>5,-font=>"Arial 8",-justify=>'right',-textvariable=>\$minimum_enrichment_for_loci_with_optimal_length)->place(-height=>14,-x=>228,-y=>649);
$prob_set5=$mw->Entry(-width=>5,-font=>"Arial 8",-justify=>'right',-textvariable=>\$minimum_enrichment_for_1T_OR_10_A_loci)->place(-height=>14,-x=>228,-y=>668);
$prob_set6=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$assume_random_basecomposition)->place(-height=>14,-width=>26,-x=>228,-y=>687);

# output
$cb_visualization=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$do_visualization)->place(-height=>14,-width=>26,-x=>550,-y=>186);
$entry_width=$mw->Entry(-width=>4,-font=>"Arial 8",-justify=>'right',-textvariable=>\$picture_width)->place(-height=>14,-x=>550,-y=>206);
$entry_height=$mw->Entry(-width=>4,-font=>"Arial 8",-justify=>'right',-textvariable=>\$picture_height)->place(-height=>14,-x=>550,-y=>225);
$cb_accent_mm=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$accent_multiple_mappers)->place(-height=>14,-width=>26,-x=>550,-y=>244);
$cb_indicate=$mw->Checkbutton(-background=>grey90,-activebackground=>AliceBlue,-state=>'disabled',-variable=>\$indicate_transcription_rate)->place(-height=>14,-width=>26,-x=>550,-y=>262);
$cb_normalize=$mw->Checkbutton(-background=>grey90,-activebackground=>AliceBlue,-state=>'disabled',-variable=>\$normalize_multiple_mappers)->place(-height=>14,-width=>26,-x=>550,-y=>282);
$entry_pixel=$mw->Entry(-width=>2,-font=>"Arial 8",-justify=>'right',-background=>grey90,-state=>'disabled',-textvariable=>\$pixel_for_one_transcript)->place(-height=>14,-width=>26,-x=>550,-y=>301);
$cb_output_summary=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$output_summary)->place(-height=>14,-width=>26,-x=>550,-y=>321);
$cb_sort_summary=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$sort_summary_by_score)->place(-height=>14,-width=>26,-x=>550,-y=>340);
$cb_average=$mw->Checkbutton(-background=>White,-state=>'disabled',-background=>grey90,-activebackground=>AliceBlue,-variable=>\$calculate_average_transcription)->place(-height=>14,-width=>26,-x=>550,-y=>359);
$cb_ao1=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$output_clustered)->place(-height=>14,-width=>26,-x=>550,-y=>378);
$cb_ao2=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$output_clustered_unique)->place(-height=>14,-width=>26,-x=>550,-y=>397);
$cb_ao3=$mw->Checkbutton(-background=>White,-activebackground=>AliceBlue,-variable=>\$output_clustered_multi)->place(-height=>14,-width=>26,-x=>550,-y=>417);
$entry_cutoff_all=$mw->Entry(-background=>grey90,-state=>'disabled',-width=>5,-font=>"Arial 8",-justify=>'right',-textvariable=>\$transcription_cutoff_all)->place(-height=>14,-x=>725,-y=>378);
$entry_cutoff_unique=$mw->Entry(-background=>grey90,-state=>'disabled',-width=>5,-font=>"Arial 8",-justify=>'right',-textvariable=>\$transcription_cutoff_unique)->place(-height=>14,-x=>725,-y=>397);
$entry_cutoff_multi=$mw->Entry(-background=>grey90,-state=>'disabled',-width=>5,-font=>"Arial 8",-justify=>'right',-textvariable=>\$transcription_cutoff_multi)->place(-height=>14,-x=>725,-y=>417);

# buttons
$show_time=1;
$hide_time=0;
$track=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/track");
$quit=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/exit");
$help=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/doc");
$default=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/defaults");
$load=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/load");
$save=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/save");
$stop=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/stop");
$refresh=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/refresh");
$clock=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/clock");
$noclock=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/noclock");
$cses=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/cses");
$fses=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/fses");
$closeses=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/closeses");
$export=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/export");
$info=$mw->Photo(-format=>'png',-file=>"$programfiles/info");
$button_track=$mw->Button(-image=>$track,-background=>White,-command=>\&check_settings)->place(-width=>38,-height=>38,-x=>315,-y=>83);
$button_quit=$mw->Button(-image=>$quit,-background=>White,-command=>sub{unlink"prev_temp";if($directory_former_session){unlink"$directory_former_session/temp_stat"};exit;})->place(-width=>38,-height=>38,-x=>715,-y=>83);
$button_help=$mw->Button(-image=>$help,-background=>White,-command=>\&info)->place(-width=>38,-height=>38,-x=>365,-y=>83);
$button_defaults=$mw->Button(-image=>$default,-background=>White,-command=>sub{$assume_random_basecomposition=0;$output_clustered_multi=0;$output_clustered_unique=0;$output_clustered=0;$minimum_enrichment_for_1T_OR_10_A_loci=2;$minimum_enrichment_for_loci_with_optimal_length=2;$minimum_enrichment_for_rare_loci=2;$minimum_strand_bias=2;$significance_piRNA_density=0.01;$minimum_piRNA_loci_per_cluster=2;$consider_only_unique_mappers=0;$minimum_normalized_reads=0;$minimum_unique_mappers=0;$minimum_piRNAdensity_per_cluster_entry=0.1;$minimum_size_per_cluster=100;$maximum_size_per_cluster=1000000;$do_monodirectional=1;$do_bidirectional=1;$do_nondirectional=1;$directionality_threshold=75;$minimum_U_loci=0;$minimum_10A_loci=0;$minimum_desired_length_loci=0;$desired_length_minimum=26;$desired_length_maximum=32;$do_visualization=1;$accent_multiple_mappers=1;$normalize_multiple_mappers=0;$indicate_transcription_rate=0;$picture_width=560;$picture_height=220;$pixel_for_one_transcript=3;$simple2->configure(-textvariable=>\$minimum_normalized_reads);$simple3->configure(-textvariable=>\$minimum_unique_mappers);})->place(-width=>38,-height=>38,-x=>415,-y=>83);
$button_load=$mw->Button(-image=>$load,-background=>White,-command=>\&load_settings)->place(-width=>38,-height=>38,-x=>515,-y=>83);
$button_save=$mw->Button(-image=>$save,-background=>White,-command=>\&save_settings)->place(-width=>38,-height=>38,-x=>565,-y=>83);
$button_stop=$mw->Button(-image=>$stop,-background=>White,-state=>'disabled',-command=>sub{$interrupt=1;})->place(-width=>38,-height=>38,-x=>665,-y=>83);
$button_refresh=$mw->Button(-image=>$refresh,-background=>White,-command=>sub{refresh_preview();$preview_label->destroy;$preview_pane->destroy;$preview_pane=$mw->Scrolled('Pane',-scrollbars=>'osoe',-background=>White,-sticky=>'nw',-gridded=>'y')->place(-width=>470,-height=>241,-x=>775,-y=>197);$preview_label=$preview_pane->Label(-image=>$preview_image)->pack();})->place(-width=>38,-height=>38,-x=>775,-y=>157);
$button_clock=$mw->Button(-image=>$clock,-background=>White,-command=>\&show_time,-state=>'disabled')->place(-width=>38,-height=>38,-x=>790,-y=>83);
$button_noclock=$mw->Button(-image=>$noclock,-background=>White,-command=>\&hide_time)->place(-width=>38,-height=>38,-x=>840,-y=>83);
$view_cses=$mw->Button(-image=>$cses,-background=>White,-command=>\&view_current_session,-state=>'disabled')->place(-width=>67,-height=>43,-x=>10,-y=>720);
$view_fses=$mw->Button(-image=>$fses,-background=>White,-command=>\&view_former_session)->place(-width=>67,-height=>43,-x=>87,-y=>720);
$close_session=$mw->Button(-image=>$closeses,-background=>White,-command=>\&close_visualization,-state=>'disabled')->place(-width=>67,-height=>43,-x=>164,-y=>720);
$export_prob_parameters=$mw->Button(-image=>$export,-background=>White,-command=>\&export_prob_parameters,-state=>'disabled')->place(-width=>38,-height=>38,-x=>775,-y=>440);
sub export_prob_parameters
	{
	$filename_prob_parameters=$mw->getSaveFile(-title=>"Save probabilistic parameters:",-defaultextension=>'.txt',-initialdir=>'.');
	if($filename_prob_parameters)
		{
		open(SAVE_PARAMETERS,">$filename_prob_parameters");
		print SAVE_PARAMETERS"$print_parameters";
		close SAVE_PARAMETERS;
		}
	}

# print progress / results
$state_of_progress="tracking not started yet...";
$progress_pane=$mw->Scrolled('Pane',-scrollbars=>'osoe',-background=>White,-sticky=>'nw',-gridded=>'y')->place(-width=>468,-height=>245,-x=>305,-y=>460);
$progress_label=$progress_pane->Label(-font=>"Arial 8",-textvariable=>\$state_of_progress,-anchor=>'nw',-justify=>'left',-background=>White)->pack(-side=>'left',-fill=>'x');

# print probabilistic parameters
$print_parameters="no parameters available yet...";
$parameters_pane=$mw->Scrolled('Pane',-scrollbars=>'osoe',-background=>White,-sticky=>'nw',-gridded=>'y')->place(-width=>460,-height=>714,-x=>785,-y=>480);
$parameters_label=$parameters_pane->Label(-font=>"Arial 8",-textvariable=>\$print_parameters,-anchor=>'nw',-justify=>'left',-background=>White)->pack(-side=>'left',-fill=>'x');

# show preview
refresh_preview();
$preview_pane=$mw->Scrolled('Pane',-scrollbars=>'osoe',-background=>White,-sticky=>'nw',-gridded=>'y')->place(-width=>470,-height=>241,-x=>775,-y=>197);
$preview_label=$preview_pane->Label(-image=>$preview_image)->pack();

# view results
$next=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/next");
$previous=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/previous");
$goto=$mw->Photo(-format=>'jpeg',-file=>"$programfiles/goto");
$button_next=$mw->Button(-state=>'disabled',-image=>$next,-background=>White,-command=>sub{if($current_view_id<$fs_clusters){$current_view_id++}else{$current_view_id=1};actualize_visualization();})->place(-width=>41,-height=>40,-x=>245,-y=>1040);
$button_previous=$mw->Button(-state=>'disabled',-image=>$previous,-background=>White,-command=>sub{if($current_view_id>1){$current_view_id=$current_view_id-1;}else{$current_view_id=$fs_clusters;}actualize_visualization();})->place(-width=>41,-height=>40,-x=>245,-y=>1089);
$button_goto=$mw->Button(-state=>'disabled',-image=>$goto,-background=>White,-command=>sub{if($go_to_cluster=~/^\d+$/&&$go_to_cluster>=1&&$go_to_cluster<=$fs_clusters){$current_view_id=$go_to_cluster;actualize_visualization();$go_to_cluster='';}})->place(-width=>41,-height=>40,-x=>245,-y=>1138);
$entry_goto=$mw->Entry(-state=>'disabled',-width=>6,-font=>"Arial 8",-justify=>'right',-textvariable=>\$go_to_cluster)->place(-height=>15,-x=>245,-y=>1181);
$head_line=$mw->Label(-background=>White,-font=>"Arial 10",-justify=>'left',-anchor=>'w',-textvariable=>\$headline_view)->place(-width=>460,-height=>30,-x=>245,-y=>735);
$see_fasta_pane=$mw->Scrolled('Pane',-scrollbars=>'se',-background=>grey20,-sticky=>'nw',-gridded=>'y')->place(-width=>222,-height=>420,-x=>10,-y=>775);
$see_fasta=$see_fasta_pane->Label(-background=>White,-justify=>'left',-font=>"Arial 6",-textvariable=>\$view_fasta)->pack();
$see_png_pane=$mw->Scrolled('Pane',-scrollbars=>'osoe',-background=>grey20,-sticky=>'nw',-gridded=>'y')->place(-width=>525,-height=>250,-x=>245,-y=>775);
$see_png=$see_png_pane->Label()->pack();
$see_statistics=$mw->Label(-background=>grey20)->place(-width=>472,-height=>155,-x=>298,-y=>1040);

$info_toplevel_status=0;
sub info
	{
	if($info_toplevel_status==0)
		{
		$info_toplevel_status=1;
		$info_toplevel=$mw->Toplevel(-background=>"White");
		$info_toplevel->title("proTRAC manual");
		$info_toplevel->geometry("660x800");
		$info_toplevel->protocol('WM_DELETE_WINDOW',sub{$info_toplevel->destroy;$info_toplevel_status=0;});
		$info_pane=$info_toplevel->Scrolled('Pane',-scrollbars=>'osoe',-background=>White,-sticky=>'nw',-gridded=>'y')->pack(-fill=>'both',-expand=>1);		
		$info_pane->Label(-image=>$info,-background=>White)->pack();
		$info_pane->Button(-text=>" close ",-command=>sub{$info_toplevel->destroy;$info_toplevel_status=0;})->pack();
		$info_pane->Label(-background=>White,-text=>"\n\n\n")->pack();
		}
	}
sub view_current_session
	{
	$directory_former_session=$result_folder_name;
	open(SUMMARY,"$directory_former_session/proTRAC_summary.txt");
	essential_vis_part();
	}
sub view_former_session
	{
	$directory_former_session=$mw->chooseDirectory;
	if($directory_former_session)
		{
		unless(open(SUMMARY,"$directory_former_session/proTRAC_summary.txt"))
			{
			$summary_available=0;
			$open_dir=0;
			if(opendir(MONOS,"$directory_former_session/monodirectional_clusters"))
				{$open_dir++;}
			if(opendir(BIS,"$directory_former_session/bidirectional_clusters"))
				{$open_dir++;}
			if(opendir(NONS,"$directory_former_session/nondirectional_clusters"))
				{$open_dir++;}
			if($open_dir>0)
				{
				$mw->messageBox(-message=>"Could not open cluster summary file.\nNot all statistical data will be available.",-type=>'ok',-icon=>'info');
				$button_next->configure(-state=>'normal');
				$button_previous->configure(-state=>'normal');
				$button_goto->configure(-state=>'normal');
				$entry_goto->configure(-state=>'normal');
				$fs_clusters=0;
				$fs_mono_clusters=0;
				$fs_bi_clusters=0;
				$fs_non_clusters=0;
				while(defined($file=readdir(MONOS)))
					{
					if($file=~/\.fas/)
						{
						$cluster_id=$file;$cluster_id=~s/Cluster_//;$cluster_id=~s/\..+$//;
						$fs_mono_clusters++;
						}
					else{$cluster_id=0;}
					$fs_fasta_files[$cluster_id]="$directory_former_session/monodirectional_clusters/Cluster_$cluster_id.fas";
					$fs_png_files[$cluster_id]="$directory_former_session/monodirectional_clusters/Cluster_$cluster_id.png";
					if($cluster_id>$fs_clusters)
						{$fs_clusters=$cluster_id;}
					}
				closedir(MONOS);
				while(defined($file=readdir(BIS)))
					{
					if($file=~/\.fas/)
						{
						$cluster_id=$file;$cluster_id=~s/Cluster_//;$cluster_id=~s/\..+$//;
						$fs_bi_clusters++;
						}
					else{$cluster_id=0;}
					$fs_fasta_files[$cluster_id]="$directory_former_session/bidirectional_clusters/Cluster_$cluster_id.fas";
					$fs_png_files[$cluster_id]="$directory_former_session/bidirectional_clusters/Cluster_$cluster_id.png";
					if($cluster_id>$fs_clusters)
						{$fs_clusters=$cluster_id;}
					}
				closedir(BIS);
				while(defined($file=readdir(NONS)))
					{
					if($file=~/\.fas/)
						{
						$cluster_id=$file;$cluster_id=~s/Cluster_//;$cluster_id=~s/\..+$//;
						$fs_non_clusters++;
						}
					else{$cluster_id=0;}
					$fs_fasta_files[$cluster_id]="$directory_former_session/nondirectional_clusters/Cluster_$cluster_id.fas";
					$fs_png_files[$cluster_id]="$directory_former_session/nondirectional_clusters/Cluster_$cluster_id.png";
					if($cluster_id>$fs_clusters)
						{$fs_clusters=$cluster_id;}
					}
				closedir(NONS);
				$current_view_id=1;
				actualize_visualization();
				}
			else
				{
				$mw->messageBox(-message=>"Could not open any of the following folders:\nmonodirectional_clusters\nbidirectional_clusters\nnondirectional_clusters",-type=>'ok',-icon=>'error');
				}
			}
		else
			{
			$summary_available=1;
			essential_vis_part();
			sub essential_vis_part
				{
				$button_next->configure(-state=>'normal');
				$button_previous->configure(-state=>'normal');
				$button_goto->configure(-state=>'normal');
				$entry_goto->configure(-state=>'normal');
				@fs_cluster_data=();
				@fs_summary=<SUMMARY>;
				close SUMMARY;
				if(@fs_summary>4)
					{
					foreach(1..6){pop@fs_summary;}foreach(1..2){shift@fs_summary;}
					$fs_clusters=@fs_summary;
					$fs_mono_clusters=0;
					$fs_bi_clusters=0;
					$fs_non_clusters=0;
					foreach(@fs_summary)
						{
						$fs_cluster_id++;
						if($_=~/mono-directional/)
							{$fs_mono_clusters++}
						elsif($_=~/bi-directional/)
							{$fs_bi_clusters++}
						elsif($_=~/non-directional/)
							{$fs_non_clusters++}
						$fs_cluster_id=$_;
						$fs_cluster_id=~s/^Cluster //;
						$fs_cluster_id=~s/\t.+$//s;
						$fs_cluster_data[$fs_cluster_id]=$_;
						}
					@fs_summary=();
					$current_view_id=1;
					actualize_visualization();
					sub actualize_visualization
						{
						if($summary_available==1)
							{
							$percent_MS=$fs_cluster_data[$current_view_id];$percent_MS=~s/^.+directional \(//;$percent_MS=~s/%\).+$//s;
							$n_loci_stat=$fs_cluster_data[$current_view_id];$n_loci_stat=~s/^.+Loci: //;$n_loci_stat=~s/\t.+$//s;
							$n_normalized_stat=$fs_cluster_data[$current_view_id];$n_normalized_stat=~s/^.+normalized: //;$n_normalized_stat=~s/, .+$//s;
							$n_multi_stat=$fs_cluster_data[$current_view_id];$n_multi_stat=~s/^.+multi: //;$n_multi_stat=~s/, .+$//s;
							$n_unique_stat=$fs_cluster_data[$current_view_id];$n_unique_stat=~s/^.+unique: //;$n_unique_stat=~s/, .+$//s;
							$n_plus_stat=$fs_cluster_data[$current_view_id];$n_plus_stat=~s/^.+plus: //;$n_plus_stat=~s/, .+$//s;
							$n_minus_stat=$fs_cluster_data[$current_view_id];$n_minus_stat=~s/^.+minus: //;$n_minus_stat=~s/, .+$//s;
							$n_1T_stat=$fs_cluster_data[$current_view_id];$n_1T_stat=~s/^.+1T\(U\): //;$n_1T_stat=~s/ .+$//s;
							$n_10A_stat=$fs_cluster_data[$current_view_id];$n_10A_stat=~s/^.+, 10A: //;$n_10A_stat=~s/ .+$//s;
							$n_opt_length_stat=$fs_cluster_data[$current_view_id];$n_opt_length_stat=~s/^.+length: //;$n_opt_length_stat=~s/ .+$//s;
							$density_stat=$fs_cluster_data[$current_view_id];$density_stat=~s/^.+Loci\/1000bp: //;$density_stat=~s/\t.+$//s;
							$scores_stat=$fs_cluster_data[$current_view_id];$scores_stat=~s/^.+score: //;$scores_stat=~s/ .+$//s;
							$directionality_stat=$fs_cluster_data[$current_view_id];$directionality_stat=~s/^[^\t]+\t[^\t]+\t[^\t]+\t//;$directionality_stat=~s/ .+$//s;
							build_stat_picture();
							if($fs_cluster_data[$current_view_id]=~/mono-directional/)
								{
								$view_png=$mw->Photo(-format=>'png',-file=>"$directory_former_session/monodirectional_clusters/Cluster_$current_view_id.png");
								open(VIEW_FASTA,"$directory_former_session/monodirectional_clusters/Cluster_$current_view_id.fas");
								}
							elsif($fs_cluster_data[$current_view_id]=~/bi-directional/)
								{
								$view_png=$mw->Photo(-format=>'png',-file=>"$directory_former_session/bidirectional_clusters/Cluster_$current_view_id.png");
								open(VIEW_FASTA,"$directory_former_session/bidirectional_clusters/Cluster_$current_view_id.fas");
								}
							elsif($fs_cluster_data[$current_view_id]=~/non-directional/)
								{
								$view_png=$mw->Photo(-format=>'png',-file=>"$directory_former_session/nondirectional_clusters/Cluster_$current_view_id.png");
								open(VIEW_FASTA,"$directory_former_session/nondirectional_clusters/Cluster_$current_view_id.fas");
								}
							@view_fasta=<VIEW_FASTA>;
							$view_fasta=join('',@view_fasta);
							close VIEW_FASTA;
							}
						elsif($summary_available==0)
							{
							$view_png=$mw->Photo(-format=>'png',-file=>"$fs_png_files[$current_view_id]");
							open(VIEW_FASTA,"$fs_fasta_files[$current_view_id]");
							@view_fasta=<VIEW_FASTA>;
							$view_fasta=join('',@view_fasta);
							close VIEW_FASTA;
							$n_loci_stat=0;
							$n_multi_stat=0;
							$n_unique_stat=0;
							$n_plus_stat=0;
							$n_minus_stat=0;
							$n_1T_stat=0;
							$n_10A_stat=0;
							$first_coordinate_stat=999999999999999;
							$last_coordinate_stat=0;
							foreach(@view_fasta)
								{
								if($_=~/^>/)
									{
									$n_loci_stat++;
									$coord_stat=$_;$coord_stat=~s/ \d+ [UM] [+-]\n//;$coord_stat=~s/^.+ //;
									if($coord_stat<$first_coordinate_stat){$first_coordinate_stat=$coord_stat;}
									if($coord_stat>$last_coordinate_stat){$last_coordinate_stat=$coord_stat;}
									}
								elsif($_!~/^\s*$/)
									{
									if(substr($_,0,1)eq"T")
										{$n_1T_stat++}
									if(substr($_,9,1)eq"A")
										{$n_10A_stat++}
									}
								if($_=~/^>.+ M [+-]\n$/)
									{$n_multi_stat++;}
								if($_=~/^>.+ U [+-]\n$/)
									{$n_unique_stat++;}
								if($_=~/^>.+ [MU] \+\n$/)
									{$n_plus_stat++;}
								if($_=~/^>.+ [MU] -\n$/)
									{$n_minus_stat++;}
								}
							$size_stat=($last_coordinate_stat-$first_coordinate_stat)+1;
							$density_stat=($n_loci_stat/$size_stat)*1000;
							build_stat_picture_slim();
							}
						$headline_view="Cluster $current_view_id from $fs_clusters (monodirectional: $fs_mono_clusters / bidirectional: $fs_bi_clusters / nondirectional: $fs_non_clusters)";
						$head_line->update;
						$see_fasta->update;
						$see_fasta_pane->configure(-background=>White);
						$see_png_pane->configure(-background=>White);
						$see_png->update;
						$view_fses->configure(-state=>'disabled');
						$view_cses->configure(-state=>'disabled');
						$close_session->configure(-state=>'normal');
						$see_png->configure(-image=>$view_png);
						}
					}
				else
					{
					$mw->messageBox(-message=>"Folder contains no tracked clusters.",-type=>'ok',-icon=>'error');
					}
				}
			}
		}
	}
sub close_visualization
	{
	$headline_view="";$head_line->update;
	$view_fasta="";$see_fasta->update;$see_fasta_pane->configure(-background=>grey20);
	$see_png->destroy;$see_png_pane->configure(-background=>grey20);$see_png_pane->update;$see_png=$see_png_pane->Label()->pack();
	$see_statistics->destroy;$see_statistics=$mw->Label(-background=>grey20)->place(-width=>472,-height=>155,-x=>298,-y=>1040);
	$button_next->configure(-state=>'disabled');
	$button_previous->configure(-state=>'disabled');
	$button_goto->configure(-state=>'disabled');
	$entry_goto->configure(-state=>'disabled');
	if($result_folder_name)
		{$view_cses->configure(-state=>'normal');}
	else
		{$view_cses->configure(-state=>'disabled');}
	$view_fses->configure(-state=>'normal');
	$close_session->configure(-state=>'disabled');
	unlink"$directory_former_session/temp_stat";
	}
sub build_stat_picture # if cluster summary is available
	{
	$see_statistics->configure(-background=>White);
	$see_statistics->update;
	$temp_stat=new GD::Image 472,152;
	$white=$temp_stat->colorAllocate(255,255,255);
	$black=$temp_stat->colorAllocate(0,0,0);
	$light_blue=$temp_stat->colorAllocate(141,182,205);
	$firebrick3=$temp_stat->colorAllocate(205,38,38);
	$darkseagreen3=$temp_stat->colorAllocate(155,205,155);	
	$temp_stat->line(50,10,56,10,$black);
	$temp_stat->line(50,62,56,62,$black);
	$temp_stat->line(50,114,220,114,$black);
	$temp_stat->line(56,10,56,114,$black);
	foreach(1..17)
		{$temp_stat->line(64+$_,113,64+$_,(113-(($n_1T_stat/$n_loci_stat)*103)),$firebrick3)}
	foreach(1..17)
		{$temp_stat->line(98+$_,113,98+$_,(113-(($n_10A_stat/$n_loci_stat)*103)),$darkseagreen3)}
	foreach(1..17)
		{$temp_stat->line(130+$_,113,130+$_,(113-($percent_MS)*1.03),$light_blue)}
	foreach(1..17)
		{$temp_stat->line(161+$_,113,161+$_,(113-(($n_opt_length_stat/$n_loci_stat)*103)),$light_blue)}
	foreach(1..17)
		{$temp_stat->line(192+$_,113,192+$_,(113-(($n_normalized_stat/$n_loci_stat)*103)),$light_blue)}
	$temp_stat->string(gdSmallFont,12,6,"100%",$black);
	$temp_stat->string(gdSmallFont,12,58," 50%",$black);
	$temp_stat->string(gdSmallFont,12,110,"  0%",$black);
	$temp_stat->string(gdSmallFont,68,122,"1T   10A   MS   OL   N/T",$black);
	$temp_stat->string(gdTinyFont,68,142,"MS: mainstrand, OL: optimal length, N/T: normalized/total",$black);
	$temp_stat->string(gdSmallFont,250,6,"$directionality_stat",$black);
	$temp_stat->string(gdSmallFont,250,17,"Loci (total): $n_loci_stat (+: $n_plus_stat / -: $n_minus_stat)",$black);
	$temp_stat->string(gdSmallFont,250,28,"Loci (normalized): $n_normalized_stat",$black);
	$temp_stat->string(gdSmallFont,250,39,"Loci (unique): $n_unique_stat",$black);
	$temp_stat->string(gdSmallFont,250,50,"Loci (redundant): $n_multi_stat",$black);
	$temp_stat->string(gdSmallFont,250,61,"Loci with 1T: $n_1T_stat",$black);
	$temp_stat->string(gdSmallFont,250,72,"Loci with 10A: $n_10A_stat",$black);
	$temp_stat->string(gdSmallFont,250,83,"Loci with opt. length: $n_opt_length_stat",$black);
	$temp_stat->string(gdSmallFont,250,94,"Loci density [loci/kb]: $density_stat",$black);
	$temp_stat->string(gdSmallFont,250,105,"Cluster score: $scores_stat",$black);
	open(TEMP_STAT,">$directory_former_session/temp_stat");
	binmode TEMP_STAT;
	print TEMP_STAT $temp_stat->png;
	close TEMP_STAT;
	$temp_stat_png=$mw->Photo(-format=>'png',-file=>"$directory_former_session/temp_stat");
	$see_statistics->configure(-image=>$temp_stat_png);
	$see_statistics->update;
	}
sub build_stat_picture_slim # if cluster summary is NOT available
	{
	$see_statistics->configure(-background=>White);
	$see_statistics->update;
	$temp_stat=new GD::Image 472,152;
	$white=$temp_stat->colorAllocate(255,255,255);
	$black=$temp_stat->colorAllocate(0,0,0);
	$firebrick3=$temp_stat->colorAllocate(205,38,38);
	$darkseagreen3=$temp_stat->colorAllocate(155,205,155);	
	$temp_stat->line(50,10,56,10,$black);
	$temp_stat->line(50,62,56,62,$black);
	$temp_stat->line(50,114,120,114,$black);
	$temp_stat->line(56,10,56,114,$black);
	foreach(1..17)
		{$temp_stat->line(64+$_,113,64+$_,(113-(($n_1T_stat/$n_loci_stat)*103)),$firebrick3)}
	foreach(1..17)
		{$temp_stat->line(98+$_,113,98+$_,(113-(($n_10A_stat/$n_loci_stat)*103)),$darkseagreen3)}
	$temp_stat->string(gdSmallFont,12,6,"100%",$black);
	$temp_stat->string(gdSmallFont,12,58," 50%",$black);
	$temp_stat->string(gdSmallFont,12,110,"  0%",$black);
	$temp_stat->string(gdSmallFont,68,122,"1T   10A",$black);
	$temp_stat->string(gdSmallFont,150,17,"Loci (total): $n_loci_stat (+: $n_plus_stat / -: $n_minus_stat)",$black);
	$temp_stat->string(gdSmallFont,150,39,"Loci (unique): $n_unique_stat",$black);
	$temp_stat->string(gdSmallFont,150,50,"Loci (redundant): $n_multi_stat",$black);
	$temp_stat->string(gdSmallFont,150,61,"Loci with 1T: $n_1T_stat",$black);
	$temp_stat->string(gdSmallFont,150,72,"Loci with 10A: $n_10A_stat",$black);
	$temp_stat->string(gdSmallFont,150,94,"Loci density [loci/kb]: $density_stat",$black);
	open(TEMP_STAT,">$directory_former_session/temp_stat");
	binmode TEMP_STAT;
	print TEMP_STAT $temp_stat->png;
	close TEMP_STAT;
	$temp_stat_png=$mw->Photo(-format=>'png',-file=>"$directory_former_session/temp_stat");
	$see_statistics->configure(-image=>$temp_stat_png);
	$see_statistics->update;
	}

# time estimation
$estimated_elapsed_string="Total elapsed time:\t--:--:--\nEstimated remaining time (verifying):\t--:--:--\nStarts after assembling of candidates.\nMay slightly extend computation time.";
$remaining_and_elapsed_label=$mw->Label(-font=>"Arial 10",-textvariable=>\$estimated_elapsed_string,-anchor=>'nw',-justify=>'left',-background=>White)->place(-width=>300,-height=>70,-x=>900,-y=>75);
$show_time=1;
$hide_time=0;

sub show_time
	{
	$estimated_elapsed_string="Elapsed time:\t\t--:--:--\nEstimated remaining time:\t--:--:--\nStarts with verifying of clusters.\nMay slightly extend computation time.";
	$remaining_and_elapsed_label->update;
	$show_time=1;
	$hide_time=0;
	$button_clock->configure(-state=>'disabled');
	$button_noclock->configure(-state=>'normal');
	}
sub hide_time
	{
	$estimated_elapsed_string="\nClick the clock button to get a time\nestimation while computation.";
	$remaining_and_elapsed_label->update;
	$hide_time=1;
	$show_time=0;
	$button_noclock->configure(-state=>'disabled');
	$button_clock->configure(-state=>'normal');
	}

# save / load settings
sub save_settings
	{
	$types=[['proTRAC settings', '.pTs'],['All Files', '*' ]];
	$save_file_name=$mw->getSaveFile(-title=>"Save proTRAC settings",-defaultextension=>'.pTs');
	if($save_file_name)
		{
		@local_time_save=localtime;
		$local_time_save[5]+=1900;
		foreach(@local_time_save)
			{$_="0$_";}
		$minutes=substr($local_time_save[1],-2);
		$hours=substr($local_time_save[2],-2);
		$date=substr($local_time_save[3],-2);
		$month=substr($local_time_save[4],-2);$month++;
		$year=substr($local_time_save[5],-4);
		open(SAVE_FILE,">$save_file_name");	
		$save_file_content="This file contains proTRAC user settings saved on $date.$month.$year $hours"."h"."$minutes"."m\n\ninput file contains transcriptional information:\t$fasta_eq_occ_variable\nmin. cluster size:\t$minimum_size_per_cluster\nmax. cluster size:\t$maximum_size_per_cluster\nconsider only unique loci:\t$consider_only_unique_mappers\ndirectionality threshold:\t$directionality_threshold\naccept mono-directional clusters:\t$do_monodirectional\naccept bi-directional clusters:\t$do_bidirectional\naccept non-directional clusters:\t$do_nondirectional\noptimal loci length range (from):\t$desired_length_minimum\noptimal loci length range (to):\t$desired_length_maximum\nmin. loci per sequence read:\t$min_loci_per_read\nmax. loci per read:\t$max_loci_per_read\nauto reconsider with loci/read threshold:\t$frequently_threshold\nperform auto reconsideration:\t$do_reconsideration\nmin. loci per cluster (absolute):\t$minimum_piRNA_loci_per_cluster\nmin. loci per cluster (normalized):\t$minimum_normalized_reads\nmin. loci per cluster (unique):\t$minimum_unique_mappers\nmin. loci density:\t$minimum_piRNAdensity_per_cluster_entry\nmin. loci with T at pos. 1:\t$minimum_U_loci\nmin. loci with A at pos. 10:\t$minimum_10A_loci\nmin. loci with optimal length:\t$minimum_desired_length_loci\np for piRNA density:\t$significance_piRNA_density\nmin. score for strand bias:\t$minimum_strand_bias\nmin. score for acc. of rare loci:\t$minimum_enrichment_for_rare_loci\nmin. score for acc. of loci with optimal length:\t$minimum_enrichment_for_loci_with_optimal_length\nmin. score for acc. of loci with 1T or 10A:\t$minimum_enrichment_for_1T_OR_10_A_loci\nbased on random base composition (25% each):\t$assume_random_basecomposition\nvisualize clusters:\t$do_visualization\npicture width:\t$picture_width\npicture height:\t$picture_height\naccent multiple mappers:\t$accent_multiple_mappers\nindicate transcription rate for each locus:\t$indicate_transcription_rate\nnormalize multiple mappers:\t$normalize_multiple_mappers\npixel per read:\t$pixel_for_one_transcript\noutput cluster summary file:\t$output_summary\nsort summary by score values:\t$sort_summary_by_score\ncalculate av. locus transcription for each cluster:\t$calculate_average_transcription\nseperate output of clustered loci:\t$output_clustered\nmin. transcription cutoff (all):\t$transcription_cutoff_all\nseperate output of clustered & unique loci:\t$output_clustered_unique\nmin. transcription cutoff (unique):\t$transcription_cutoff_unique\nseperate output of clustered & multiple loci:\t$output_clustered_multi\nmin. transcription cutoff (multiple):\t$transcription_cutoff_multi";
		print SAVE_FILE$save_file_content;
		close SAVE_FILE;
		}
	}
sub load_settings
	{
	$open_file=$mw->getOpenFile(-title => "Select a file to open",-defaultextension =>'.pTs',-filetypes=>$types );
	if(open(OPEN_FILE,"$open_file"))
		{
		@open_file=<OPEN_FILE>;
		close OPEN_FILE;
		if($open_file[0]=~/^This file contains proTRAC user settings saved on /)
			{
			shift@open_file;
			shift@open_file;
			foreach(@open_file)
				{
				chomp$_;
				$_=~s/^[^\:]+\:\t//;
				}
			if(@open_file==43)
				{
				$fasta_eq_occ_variable=$open_file[0];$minimum_size_per_cluster=$open_file[1];$maximum_size_per_cluster=$open_file[2];$consider_only_unique_mappers=$open_file[3];$directionality_threshold=$open_file[4];$do_monodirectional=$open_file[5];$do_bidirectional=$open_file[6];$do_nondirectional=$open_file[7];$desired_length_minimum=$open_file[8];$desired_length_maximum=$open_file[9];$min_loci_per_read=$open_file[10];$max_loci_per_read=$open_file[11];$frequently_threshold=$open_file[12];$do_reconsideration=$open_file[13];$minimum_piRNA_loci_per_cluster=$open_file[14];$minimum_normalized_reads=$open_file[15];$minimum_unique_mappers=$open_file[16];$minimum_piRNAdensity_per_cluster_entry=$open_file[17];$minimum_U_loci=$open_file[18];$minimum_10A_loci=$open_file[19];$minimum_desired_length_loci=$open_file[20];$significance_piRNA_density=$open_file[21];$minimum_strand_bias=$open_file[22];$minimum_enrichment_for_rare_loci=$open_file[23];$minimum_enrichment_for_loci_with_optimal_length=$open_file[24];$minimum_enrichment_for_1T_OR_10_A_loci=$open_file[25];$assume_random_basecomposition=$open_file[26];$do_visualization=$open_file[27];$picture_width=$open_file[28];$picture_height=$open_file[29];$accent_multiple_mappers=$open_file[30];$indicate_transcription_rate=$open_file[31];$normalize_multiple_mappers=$open_file[32];$pixel_for_one_transcript=$open_file[33];$output_summary=$open_file[34];$sort_summary_by_score=$open_file[35];$calculate_average_transcription=$open_file[36];$output_clustered=$open_file[37];$transcription_cutoff_all=$open_file[38];$output_clustered_unique=$open_file[39];$transcription_cutoff_unique=$open_file[40];$output_clustered_multi=$open_file[41];$transcription_cutoff_multi=$open_file[42];
				if($fasta_eq_occ_variable eq "YES")
					{
					$cb_normalize->configure(-background=>White,-state=>'normal');
					$cb_indicate->configure(-background=>White,-state=>'normal');
					$entry_pixel->configure(-background=>White,-state=>'normal');
					$cb_average->configure(-background=>White,-state=>'normal');
					$entry_cutoff_all->configure(-background=>White,-state=>'normal');
					$entry_cutoff_unique->configure(-background=>White,-state=>'normal');
					$entry_cutoff_multi->configure(-background=>White,-state=>'normal');
					}
				}
			else
				{
				$mw->messageBox(-message=>"File seems to be incomplete.\nParameter assignment failed.",-type=>'ok',-icon=>'error');
				}
			}
		else
			{
			$mw->messageBox(-message=>"File is damaged or does not contain proTRAC settings.",-type=>'ok',-icon=>'error');
			}
		}
	else
		{
		$mw->messageBox(-message=>"Could not open file:\n$open_file",-type=>'ok',-icon=>'error');
		}
	}

@widgets=($export_prob_parameters,$view_cses,$view_fses,$button_clock,$button_noclock,$fasta_eq_occ,$entry_input_file,$button_browse_input_file,$simple1,$simple2,$simple3,$simple4,$simple5,$simple6,$simple7,$prob_set1,$prob_set2,$prob_set3,$prob_set4,$prob_set5,$prob_set6,$general1,$general2,$general3,$general4,$general5,$general6,$general7,$general8,$general9,$general10,$general11,$general12,$general13,$cb_visualization,$entry_width,$entry_height,$cb_accent_mm,$cb_indicate,$cb_normalize,$entry_pixel,$cb_output_summary,$cb_sort_summary,$cb_average,$cb_ao1,$cb_ao2,$cb_ao3,$entry_cutoff_all,$entry_cutoff_unique,$entry_cutoff_multi,$button_track,$button_quit,$button_help,$button_defaults,$button_load,$button_save,$button_refresh);
MainLoop;

sub filter_ELAND3_file
	{
	$state_of_progress="Filtering input for reads that map $min_loci_per_read-$max_loci_per_read times...";
	$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
	%filter_hash=();
	open(IN,"$input_file_name");
	while(<IN>)
		{
		$seq=$_;
		$seq=~s/[^\t]+\t\d+\t//;
		$seq=~s/\t.+$//s;
		$filter_hash{$seq}++;
		}
	close IN;
	$create_out_file_name=$input_file_name;
	$create_out_file_name=~s/\..+$//;
	open(OUT,">$create_out_file_name(map$min_loci_per_read-$max_loci_per_read).txt");
	open(IN,"$input_file_name");
	while(<IN>)
		{
		$seq=$_;
		$seq=~s/[^\t]+\t\d+\t//;
		$seq=~s/\t.+$//s;
		if($filter_hash{$seq}>=$min_loci_per_read&&$filter_hash{$seq}<=$max_loci_per_read)
			{
			print OUT $_;
			}
		}
	close IN;
	close OUT;
	$input_file_name="$create_out_file_name(map$min_loci_per_read-$max_loci_per_read).txt";
	%filter_hash=();
	$state_of_progress.=" done.\n";
	$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
	}

###   CHECK USER SETTINGS   ###
sub check_settings
	{
	$error_status=0;
	$error_message="";
	if(open(TEST_INPUT,$input_file_name))
		{
		$seqmap_line=<TEST_INPUT>;
		if($seqmap_line!~/^trans_id\ttrans_coord\ttarget_seq\tprobe_id\tprobe_seq\tnum_mismatch\tstrand\n$/&&$error_status==0)
			{$error_status=1;$error_message.="\nInput file seems to be no SeqMap ELAND3 output.\nRun SeqMap with option: /output_all_matches";}
		close TEST_INPUT;
		}
	else
		{
		$error_status=1;
		$error_message.="\nCould not open input file:\n$input_file_name";
		}
	if($minimum_piRNA_loci_per_cluster!~/^\d+$/||$minimum_piRNA_loci_per_cluster<2)
		{$error_status=1;$error_message.="\nMinimum loci per cluster has to be an integer >=2.";}
	if($minimum_normalized_reads!~/^\d+\.*\d*$/||$minimum_normalized_reads<0)
		{$error_status=1;$error_message.="\nMinimum loci (normalized) has to be numerical >=0.";}
	if($minimum_normalized_reads>$minimum_piRNA_loci_per_cluster&&$consider_only_unique_mappers==0)
		{$error_status=1;$error_message.="\nILLOGICAL: Minimum loci (normalized) must not exceed minimum loci.";}
	if($minimum_unique_mappers!~/^\d+$/||$minimum_unique_mappers<0)
		{$error_status=1;$error_message.="\nMinimum unique loci per cluster has to be an integer >=0.";}
	if($minimum_unique_mappers>$minimum_normalized_reads&&$consider_only_unique_mappers==0)
		{$error_status=1;$error_message.="\nILLOGICAL: Minimum unique loci per cluster must not exceed minimum loci (normalized).";}
	if($minimum_unique_mappers>$minimum_piRNA_loci_per_cluster&&$consider_only_unique_mappers==0)
		{$error_status=1;$error_message.="\nILLOGICAL: Minimum unique loci per cluster must not exceed minimum loci.";}
	if($minimum_piRNAdensity_per_cluster_entry!~/^\d+\.*\d*$/||$minimum_piRNAdensity_per_cluster_entry<=0)
		{$error_status=1;$error_message.="\nMinimum loci density has to be numerical >0.";}
	if($minimum_size_per_cluster!~/^\d+$/)
		{$error_status=1;$error_message.="\nMinimum size per cluster has to be an integer >=0.";}
	if($maximum_size_per_cluster!~/^\d+$/||$maximum_size_per_cluster<=0)
		{$error_status=1;$error_message.="\nMaximum size per cluster has to be an integer >0.";}
	if($maximum_size_per_cluster<=$minimum_size_per_cluster)
		{$error_status=1;$error_message.="\nILLOGICAL: Maximum size per cluster has to exceed minimum size per cluster.";}
	if($directionality_threshold!~/^\d+\.*\d*$/||$directionality_threshold>100||$directionality_threshold<=50)
		{$error_status=1;$error_message.="\nDirectionality threshold has to be numerical (>50/<=100).";}
	if($minimum_U_loci!~/^\d+\.*\d*$/||$minimum_U_loci>100||$minimum_U_loci<0)
		{$error_status=1;$error_message.="\nMinimum loci with T at pos. 1 has to be numerical (>=0/<=100).";}
	if($minimum_10A_loci!~/^\d+\.*\d*$/||$minimum_10A_loci>100||$minimum_10A_loci<0)
		{$error_status=1;$error_message.="\nMinimum loci with A at pos. 10 has to be numerical (>=0/<=100).";}
	if($minimum_desired_length_loci!~/^\d+\.*\d*$/||$minimum_desired_length_loci>100||$minimum_desired_length_loci<0)
		{$error_status=1;$error_message.="\nMinimum loci with optimal length has to be numerical (>=0/<=100).";}
	if($desired_length_minimum!~/^\d+$/)
		{$error_status=1;$error_message.="\nLower limit of optimal length has to be an integer.";}
	if($desired_length_maximum!~/^\d+$/)
		{$error_status=1;$error_message.="\nUpper limit of optimal length has to be an integer.";}
	if($min_loci_per_read!~/^\d+$/||$min_loci_per_read==0)
		{$error_status=1;$error_message.="\nMinimum number of loci per read has to be an integer >0.";}
	if($max_loci_per_read!~/^\d*$/)
		{$error_status=1;$error_message.="\nMaximum number of loci per read has to be an integer >0.";}
	if($max_loci_per_read=~/^\d+$/&&$max_loci_per_read<$min_loci_per_read)
		{$error_status=1;$error_message.="\nILLOGICAL: Minimum number of loci per read exceeds maximum number of loci per read.";}
	if($desired_length_maximum<$desired_length_minimum)
		{$error_status=1;$error_message.="\nILLOGICAL: Upper limit of optimal length has to exceed (or equal) lower limit.";}
	if($frequently_threshold!~/^\d+$/)
		{$error_status=1;$error_message.="\nThreshold for auto reconsider has to be an integer >0.";}
	if($do_monodirectional+$do_bidirectional+$do_nondirectional==0)
		{$error_status=1;$error_message.="\nChoose at least one cluster category (directionality).";}
	if($picture_width!~/^\d+$/||$picture_width<250)
		{$error_status=1;$error_message.="\nPicture width has to be an integer (min. 250 pixel).";}
	if($picture_height!~/^\d+$/||$picture_height<100)
		{$error_status=1;$error_message.="\nPicture height has to be an integer (min. 100 pixel).";}
	if($pixel_for_one_transcript!~/^\d+$/||$pixel_for_one_transcript<=0)
		{$error_status=1;$error_message.="\nPixel per transcript has to be an integer >0.";}
	if($fasta_eq_occ_variable eq"YES"&&$transcription_cutoff_all!~/^\d+$/&&$transcription_cutoff_all)
		{$error_status=1;$error_message.="\nMinimum transcription cutoff (clustered) has to be an integer >0.";}
	elsif($fasta_eq_occ_variable eq"YES"&&$transcription_cutoff_all==0)
		{$error_status=1;$error_message.="\nMinimum transcription cutoff (clustered) has to be an integer >0.";}
	if($fasta_eq_occ_variable eq"YES"&&$transcription_cutoff_unique!~/^\d+$/&&$transcription_cutoff_unique)
		{$error_status=1;$error_message.="\nMinimum transcription cutoff (clustered & unique) has to be an integer >0.";}
	elsif($fasta_eq_occ_variable eq"YES"&&$transcription_cutoff_unique==0)
		{$error_status=1;$error_message.="\nMin. transcription cutoff (clustered & unique) has to be an integer >0.";}
	if($fasta_eq_occ_variable eq"YES"&&$transcription_cutoff_multi!~/^\d+$/&&$transcription_cutoff_multi)
		{$error_status=1;$error_message.="\nMin. transcription cutoff (clustered & multiple) has to be an integer >0.";}
	elsif($fasta_eq_occ_variable eq"YES"&&$transcription_cutoff_multi==0)
		{$error_status=1;$error_message.="\nMin. transcription cutoff (clustered & multiple) has to be an integer >0.";}
	if($significance_piRNA_density!~/^[10]+\.*\d*$/||$significance_piRNA_density==0||$significance_piRNA_density>1)
		{$error_status=1;$error_message.="\nP for piRNA density has to be numerical >0 <=1 (e.g. 0.01).";}
	if($minimum_strand_bias!~/^\d+\.*\d*$/)
		{$error_status=1;$error_message.="\n.Min. score for strand bias has to be numerical >=0.";}
	if($minimum_enrichment_for_rare_loci!~/^\d+\.*\d*$/)
		{$error_status=1;$error_message.="\n.Min. score for accumulation of rare loci has to be numerical >=0.";}
	if($minimum_enrichment_for_loci_with_optimal_length!~/^\d+\.*\d*$/)
		{$error_status=1;$error_message.="\n.Min. score for accumulation of loci with optimal length has to be numerical >=0.";}
	if($minimum_enrichment_for_1T_OR_10_A_loci!~/^\d+\.*\d*$/)
		{$error_status=1;$error_message.="\n.Min. score for accumulation of loci with optimal length has to be numerical >=0.";}
	
	if($error_status==1)
		{
		$mw->messageBox(-message=>"Improper settings:\n$error_message",-type=>'ok',-icon=>'error');
		}
	else
		{
		$interrupt=0;
		configure_widgets();
		if($min_loci_per_read>1||$max_loci_per_read=~/^\d+$/)
			{
			filter_ELAND3_file();
			}
		execute();
		}
	}

sub configure_widgets
	{
	foreach(@widgets)		
		{$_->configure(-state=>'disabled');}
	$button_stop->configure(-state=>'normal');
	}

###   START TRACKING   ###
sub execute
{
$start_time=time;
$print_parameters="no parameters available yet...";
$parameters_label->update;
fasta_referres_to_occurence();
sub fasta_referres_to_occurence
	{
	if($fasta_eq_occ_variable eq "YES")
		{
		$FASTA_refferes_to_occurence=1;
		}
	elsif($fasta_eq_occ_variable eq "NO")
		{
		$FASTA_refferes_to_occurence=0;
		}
	}
$min_strand_specifity=$directionality_threshold/100;
$minimum_U_loci_relative=$minimum_U_loci/100;
$minimum_10A_loci_relative=$minimum_10A_loci/100;
$minimum_desired_length_loci_relative=$minimum_desired_length_loci/100;
if($show_time==1)
	{
	$estimated_elapsed_string="\nElapsed time:\t\t--:--:--\nEstimated remaining time:\t--:--:--";
	}

###   CALCULATE FACTORIALS FOR SCORING   ###
unless(@factorials)
	{
	$state_of_progress="Calculating factorials for probabilistic tracking...";
	$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
	use bignum;
	rational_factorials();
	@factorials=('1','1');
	$factorial_limit=1000;
	$factorial=1;
	foreach(2..$factorial_limit)
		{
		$factorial=$factorial*$_;
		push(@factorials,$factorial);
		}
	no bignum;
	$state_of_progress.=" done.\n";
	$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
	}

###   CREATE RESULT FOLDERS   ###
@local_time=localtime;
$local_time[5]+=1900;
foreach(@local_time)
	{
	$_="0$_";
	}
$minutes=substr($local_time[1],-2);
$hours=substr($local_time[2],-2);
$date=substr($local_time[3],-2);
$month=substr($local_time[4],-2);$month++;
$year=substr($local_time[5],-4);
$result_folder_name="proTRAC_results_$date.$month.$year $hours"."h$minutes"."m";
opendir(DIR,".");
@files=readdir(DIR);
close DIR;
$index=1;
while($result_folder_name~~@files)
	{
	$index++;
	$result_folder_name=~s/_\(\d+\)$//;
	$result_folder_name.="_($index)";
	}
mkdir("$result_folder_name");
mkdir("$result_folder_name/prob_charts");
if($do_monodirectional==1)
	{
	mkdir("$result_folder_name/monodirectional_clusters");
	}
if($do_bidirectional==1)
	{
	mkdir("$result_folder_name/bidirectional_clusters");
	}
if($do_nondirectional==1)
	{
	mkdir("$result_folder_name/nondirectional_clusters");
	}

###   BUILD SEQUENCE HASH (key -> Seq / value -> n loci) / count seqs inside+outside optimum / count 1T&10A content / chromosomal distribution   ###
$state_of_progress.="Importing data from $input_file_name...";
$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
%sequence_hash=();
$count_matches=0;
$seqs_inside_opt=0;
$seqs_outside_opt=0;
%hits_per_chromosome_or_scaffold=();
%first_last_hit_per_chromosome_or_scaffold=();
%hit_comprising_range_per_chromosome_or_scaffold=();
open(INPUT,$input_file_name)||print"\nERROR: could not open $input_file_name\n";
$previous_trans_id="+++\tnot initialized\t+++";
$previous_trans_coord="+++\tnot initialized\t+++";
while(<INPUT>)
	{
	last if $interrupt==1;
	unless($_=~/^trans_id\ttrans_coord\ttarget_seq\tprobe_id\tprobe_seq\tnum_mismatch\tstrand\n$/)
		{
		$count_matches++;
		$probe_seq=$_;
		$probe_seq=~s/^[^\t]*\t\d+\t[^\t]*\t[^\t]*\t//;
		$probe_seq=~s/\t.+//s;
		if(length$probe_seq>=$desired_length_minimum&&length$probe_seq<=$desired_length_maximum)
			{
			$seqs_inside_opt++;
			}
		if(substr($probe_seq,0,1)eq"T")
			{
			$T1_ratio_dataset++;
			}
		if(substr($probe_seq,9,1)eq"A")
			{
			$A10_ratio_dataset++;
			}
		if($FASTA_refferes_to_occurence==1)
			{
			$probe_id=$_;
			$probe_id=~s/^[^\t]*\t\d+\t[^\t]*\t//;
			$probe_id=~s/\t.+$//s;
			$sequence_hash{$probe_seq}+=(1/$probe_id);
			}
		else
			{
			$sequence_hash{$probe_seq}++;
			}
		
		# chromosomal distribution #
		$trans_id=$_;
		$trans_id=~s/\t.+//s;
		$trans_coord=$_;
		$trans_coord=~s/^[^\t]*\t//;
		$trans_coord=~s/\t.+//s;
		$hits_per_chromosome_or_scaffold{$trans_id}++;
		if($hits_per_chromosome_or_scaffold{$trans_id}==1)
			{
			$first_last_hit_per_chromosome_or_scaffold{$trans_id}="$trans_coord";
			}
		if($previous_trans_id ne$trans_id&&$first_last_hit_per_chromosome_or_scaffold{$previous_trans_id})
			{
			$hit_comprising_range_per_chromosome_or_scaffold{$previous_trans_id}=($previous_trans_coord-$first_last_hit_per_chromosome_or_scaffold{$previous_trans_id})+1;
			$first_last_hit_per_chromosome_or_scaffold{$previous_trans_id}.="-$previous_trans_coord";
			}
		$previous_trans_id=$trans_id;
		$previous_trans_coord=$trans_coord;
		}
	}
$hit_comprising_range_per_chromosome_or_scaffold{$previous_trans_id}=($previous_trans_coord-$first_last_hit_per_chromosome_or_scaffold{$previous_trans_id})+1;
$first_last_hit_per_chromosome_or_scaffold{$previous_trans_id}.="-$previous_trans_coord";
$count_sequences=scalar keys%sequence_hash;
close INPUT;
$seqs_inside_opt=$seqs_inside_opt/$count_matches;
$seqs_outside_opt=1-$seqs_inside_opt;
$T1_ratio_dataset=$T1_ratio_dataset/$count_matches;
$V1_ratio_dataset=1-$T1_ratio_dataset;
$A10_ratio_dataset=$A10_ratio_dataset/$count_matches;
$B10_ratio_dataset=1-$A10_ratio_dataset;
$state_of_progress.=" done.\n$count_sequences different sequences, $count_matches mapped loci.\nChecking loci distribution...";
$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;

###   BUILD DATASET WITH UNIQUE MAPPERS   ###
if($consider_only_unique_mappers==1)
	{
	last if $interrupt==1;
	$state_of_progress.="Build temp. ELAND3 comprising unique mappers...";
	$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
	open(INPUT,$input_file_name);
	open(TEMP_INPUT,">temp_input");
	print TEMP_INPUT"trans_id\ttrans_coord\ttarget_seq\tprobe_id\tprobe_seq\tnum_mismatch\tstrand\n";
	$accepted_loci=0;
	$rejected_loci=0;
	while(<INPUT>)
		{
		unless($_=~/^trans_id\ttrans_coord\ttarget_seq\tprobe_id\tprobe_seq\tnum_mismatch\tstrand\n$/)
			{
			$probe_seq=$_;
			$probe_seq=~s/^[^\t]*\t\d+\t[^\t]*\t[^\t]*\t//;
			$probe_seq=~s/\t.+//s;
			if($sequence_hash{$probe_seq}==1)
				{
				print TEMP_INPUT"$_";
				$accepted_loci++;
				}
			else
				{
				$rejected_loci++;
				}
			}
		}
	close INPUT;
	close TEMP_INPUT;
	$input_file_name_original=$input_file_name;
	$input_file_name="temp_input";
	$state_of_progress.=" done.\nRemaining (unique) loci: $accepted_loci, Rejected (redundant) loci: $rejected_loci";
	$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
	}

###   Build loci categories to calculate P for ratio of normalized vs total loci with given dataset   ###
$group1=0;
$group2=0;$average_group2=0;
$group3=0;$average_group3=0;
$group4=0;$average_group4=0;
$group5=0;$average_group5=0;
$group4_5=0;$average_group4_5=0;
$group3_4_5=0;$average_group3_4_5=0;
$group2_3_4_5=0;$average_group2_3_4_5=0;
foreach(keys%sequence_hash)
	{
	if($sequence_hash{$_}==1)
		{$group1++;}
	elsif($sequence_hash{$_}>=2&&$sequence_hash{$_}<=4)
		{$group2++;$average_group2+=$sequence_hash{$_};}
	elsif($sequence_hash{$_}>=5&&$sequence_hash{$_}<=10)
		{$group3++;$average_group3+=$sequence_hash{$_};}
	elsif($sequence_hash{$_}>=11&&$sequence_hash{$_}<=100)
		{$group4++;$average_group4+=$sequence_hash{$_};}
	elsif($sequence_hash{$_}>=101)
		{$group5++;$average_group5+=$sequence_hash{$_};}
	if($sequence_hash{$_}>=11)
		{$group4_5++;$average_group4_5+=$sequence_hash{$_};}
	if($sequence_hash{$_}>=5)
		{$group3_4_5++;$average_group3_4_5+=$sequence_hash{$_};}
	if($sequence_hash{$_}>=2)
		{$group2_3_4_5++;$average_group2_3_4_5+=$sequence_hash{$_};}
	}
unless($group2==0)
	{$average_group2=$average_group2/$group2;}
unless($group3==0)
	{$average_group3=$average_group3/$group3;}
unless($group4==0)
	{$average_group4=$average_group4/$group4;}
unless($group5==0)
	{$average_group5=$average_group5/$group5;}
unless($group4_5==0)
	{$average_group4_5=$average_group4_5/$group4_5;}
unless($group3_4_5==0)
	{$average_group3_4_5=$average_group3_4_5/$group3_4_5;}
unless($group2_3_4_5==0)
	{$average_group2_3_4_5=$average_group2_3_4_5/$group2_3_4_5;}

$group2=$group2*$average_group2;
$group3=$group3*$average_group3;
$group4=$group4*$average_group4;
$group5=$group5*$average_group5;
$group4_5=$group4_5*$average_group4_5;
$group3_4_5=$group3_4_5*$average_group3_4_5;
$group2_3_4_5=$group2_3_4_5*$average_group2_3_4_5;

unless($average_group2==0)
	{$average_group2=1/$average_group2;}
unless($average_group3==0)
	{$average_group3=1/$average_group3;}
unless($average_group4==0)
	{$average_group4=1/$average_group4;}
unless($average_group5==0)
	{$average_group5=1/$average_group5;}
unless($average_group4_5==0)
	{$average_group4_5=1/$average_group4_5;}
unless($average_group3_4_5==0)
	{$average_group3_4_5=1/$average_group3_4_5;}
unless($average_group2_3_4_5==0)
	{$average_group2_3_4_5=1/$average_group2_3_4_5;}

$seqs_inside_opt_print=(int(($seqs_inside_opt*10000)+0.5))/100;
$T1_ratio_dataset_print=(int(($T1_ratio_dataset*10000)+0.5))/100;
$A10_ratio_dataset_print=(int(($A10_ratio_dataset*10000)+0.5))/100;
$print_parameters="Build 8 loci categories depending on loci per read:\nGroup 1 (1/1):\t\t$group1 loci each with 1 read\nGroup 2 (1/2-1/4):\t\t$group2 loci each with $average_group2 (av.) reads\nGroup 3 (1/5-1/10):\t\t$group3 loci each with $average_group3 (av.) reads\nGroup 4 (1/11-1/100):\t$group4 loci each with $average_group4 (av.) reads\nGroup 5 (<1/100):\t\t$group5 loci each with $average_group5 (av.) reads\nGroup 6 (<1):\t\t$group2_3_4_5 loci each with $average_group2_3_4_5 (av.) reads\nGroup 7 (<1/4):\t\t$group3_4_5 loci each with $average_group3_4_5 (av.) reads\nGroup 8 (<1/10):\t\t$group4_5 loci each with $average_group4_5 (av.) reads\nLoci inside stated optimum: $seqs_inside_opt_print%\nLoci with T at pos.1: $T1_ratio_dataset_print%\nLoci with A at pos.10: $A10_ratio_dataset_print%\n\n";
$parameters_label->update;

###   COMPUTE MINIMUM NUMBER OF LOCI TO REACH SIGNIFICANCE   ###
# strandbias
$index=0;
$min_loci_strand=1;
while($index==0)
	{
	$min_loci_strand++;
	if(0.5**$min_loci_strand<(1/(10**$minimum_strand_bias)))
		{
		$index=1;
		}
	}
$min_loci_strand++; # p ++/-- = 0.5 not 0.25
$print_parameters.="Minimum loci to get significant strand bias: $min_loci_strand\n";
$parameters_label->update;

# rare loci
$index=0;
$min_loci_rare=1;
if($group1>0&&$group5>0&&$minimum_enrichment_for_rare_loci>0)
	{
	while($index==0)
		{
		$min_loci_rare++;
		if(($group1/$count_matches)**$min_loci_rare<(1/(10**$minimum_enrichment_for_rare_loci)))
			{
			$index=1;
			}
		}
	$print_parameters.="Minimum loci to get significant enrichment of rare loci: $min_loci_rare\n";
	$parameters_label->update;
	}
elsif($group2>0&&$group4_5>0&&$minimum_enrichment_for_rare_loci>0)
	{
	while($index==0)
		{
		$min_loci_rare++;
		if(($group2/$count_matches)**$min_loci_rare<(1/(10**$minimum_enrichment_for_rare_loci)))
			{
			$index=1;
			}
		}
	$print_parameters.="Minimum loci to get significant enrichment of rare loci: $min_loci_rare\n";
	$parameters_label->update;
	}
elsif($group3>0&&$group3_4_5>0&&$minimum_enrichment_for_rare_loci>0)
	{
	while($index==0)
		{
		$min_loci_rare++;
		if(($group3/$count_matches)**$min_loci_rare<(1/(10**$minimum_enrichment_for_rare_loci)))
			{
			$index=1;
			}
		}
	$print_parameters.="Minimum loci to get significant enrichment of rare loci: $min_loci_rare\n";
	$parameters_label->update;
	}
elsif($group4>0&&$group2_3_4_5>0&&$minimum_enrichment_for_rare_loci>0)
	{
	while($index==0)
		{
		$min_loci_rare++;
		if(($group4/$count_matches)**$min_loci_rare<(1/(10**$minimum_enrichment_for_rare_loci)))
			{
			$index=1;
			}
		}
	$print_parameters.="Minimum loci to get significant enrichment of rare loci: $min_loci_rare\n";
	$parameters_label->update;
	}
elsif($minimum_enrichment_for_rare_loci!=0)
	{
	if($group2+$group3+$group4+$group5==0||$group1+$group3+$group4+$group5==0||$group1+$group2+$group4+$group5==0||$group1+$group2+$group3+$group5==0||$group1+$group2+$group3+$group4==0)
		{
		$what_to_do=$mw->messageBox(-message=>"All loci exhibit same abundance. No accumulation of rare loci possible!\nTo continue with minimum score =0 press OK.\nTo cancel computation press CANCEL.",-type=>'okcancel',-icon=>'error');
		if($what_to_do=~/ok/i)
			{
			$minimum_enrichment_for_rare_loci=0;
			}
		elsif($what_to_do=~/cancel/i)
			{
			$interrupt=1;
			}
		}
	}

# optimal length
$index=0;
$min_loci_opt=1;
if($seqs_inside_opt!=1&&$seqs_inside_opt!=0&&$minimum_enrichment_for_loci_with_optimal_length>0)
	{
	while($index==0)
		{
		$min_loci_opt++;
		if($seqs_inside_opt**$min_loci_opt<(1/(10**$minimum_enrichment_for_loci_with_optimal_length)))
			{
			$index=1;
			}
		}
	$print_parameters.="Minimum loci to get significant enrichment of loci with optimal length: $min_loci_opt\n";
	$parameters_label->update;
	}
elsif($minimum_enrichment_for_loci_with_optimal_length!=0)
	{
	if($seqs_inside_opt==1){$all_or_no="All";}elsif($seqs_inside_opt==0){$all_or_no="No";}
	$what_to_do=$mw->messageBox(-message=>"$all_or_no loci exhibit optimal length. No accumulation of loci with optimal length possible!\nTo continue with minimum score =0 press OK.\nTo cancel computation press CANCEL.",-type=>'okcancel',-icon=>'error');
	if($what_to_do=~/ok/i)
		{
		$minimum_enrichment_for_loci_with_optimal_length=0;
		}
	elsif($what_to_do=~/cancel/i)
		{
		$interrupt=1;
		}
	}

# 1T
if($assume_random_basecomposition==1)
	{
	$T1_ratio_dataset=0.25;
	$A10_ratio_dataset=0.25;
	}
$index=0;
$all_1T=0;
$min_loci_1T=1;
if($T1_ratio_dataset!=1&&$T1_ratio_dataset!=0&&$minimum_enrichment_for_1T_OR_10_A_loci>0)
	{
	while($index==0)
		{
		$min_loci_1T++;
		if($T1_ratio_dataset**$min_loci_1T<(1/(10**$minimum_enrichment_for_1T_OR_10_A_loci)))
			{
			$index=1;
			}
		}
	$print_parameters.="Minimum loci to get significant enrichment of 1T loci : $min_loci_1T\n";
	$parameters_label->update;
	}
else
	{
	$all_1T=1;
	}

# 10A
$index=0;
$min_loci_10A=1;
if($A10_ratio_dataset!=1&&$A10_ratio_dataset!=0&&$minimum_enrichment_for_1T_OR_10_A_loci>0)
	{
	while($index==0)
		{
		$min_loci_10A++;
		if($A10_ratio_dataset**$min_loci_10A<(1/(10**$minimum_enrichment_for_1T_OR_10_A_loci)))
			{
			$index=1;
			}
		}
	$print_parameters.="Minimum loci to get significant enrichment of 10A loci : $min_loci_10A\n";
	$parameters_label->update;
	}
else
	{
	if($all_1T==1&&$minimum_enrichment_for_1T_OR_10_A_loci!=0)
		{
		$what_to_do=$mw->messageBox(-message=>"All/No loci exhibit T at pos. 1 and A at pos. 10. No basecompositional bias possible!\nTo continue with minimum score =0 press OK.\nTo cancel computation press CANCEL.",-type=>'okcancel',-icon=>'error');
		if($what_to_do=~/ok/i)
			{
			$minimum_enrichment_for_1T_OR_10_A_loci=0;
			}
		elsif($what_to_do=~/cancel/i)
			{
			$interrupt=1;
			}
		}
	}

if($min_loci_10A>$min_loci_1T)
	{$min_1T_or_10A=$min_loci_1T;}
else
	{$min_1T_or_10A=$min_loci_10A;}
$minimum_piRNA_loci_per_cluster_p=$min_loci_rare;
if($min_loci_strand>$minimum_piRNA_loci_per_cluster_p)
	{
	$minimum_piRNA_loci_per_cluster_p=$min_loci_strand;
	}
if($min_loci_opt>$minimum_piRNA_loci_per_cluster_p)
	{
	$minimum_piRNA_loci_per_cluster_p=$min_loci_opt;
	}
if($min_1T_or_10A>$minimum_piRNA_loci_per_cluster_p)
	{
	$minimum_piRNA_loci_per_cluster_p=$min_1T_or_10A;
	}
if($minimum_piRNA_loci_per_cluster_p>$minimum_piRNA_loci_per_cluster)
	{
	$minimum_piRNA_loci_per_cluster=$minimum_piRNA_loci_per_cluster_p;
	}
$minimum_size_per_cluster=$minimum_piRNA_loci_per_cluster*30; # avoid only overlapping loci
$print_parameters.="Appointed sliding window size: $minimum_piRNA_loci_per_cluster\n";
$parameters_label->update;

###   COMPUTE SIGNIFICANT PIRNA DENSITY PER KB   ###
unless($significance_piRNA_density==1)
	{
	$print_parameters.="\nLoci distribution (location, loci, range, loci densitiy, significant density):\n";
	$parameters_label->update;
	%location_specific_significant_density=();
	$chart_win=$mw->Toplevel();
	$chart_win->geometry("320x280");
	$chart_win->title("determine sign. density");
	$chart_win->stayOnTop();
	$chart_pane=$chart_win->Frame(-background=>White)->pack(-fill=>'both',-expand=>1);
	$chart_label=$chart_pane->Label(-background=>White)->pack();
	$save_chart=0;
	foreach$chr_scaf(keys(%hits_per_chromosome_or_scaffold))
		{
		last if $interrupt==1;
		if($hits_per_chromosome_or_scaffold{$chr_scaf}>=$minimum_piRNA_loci_per_cluster)
			{
			$save_chart++;
			$chromosomal_piRNA_density=($hits_per_chromosome_or_scaffold{$chr_scaf}/$hit_comprising_range_per_chromosome_or_scaffold{$chr_scaf});
			$p_loci=$chromosomal_piRNA_density;
			$p_no_loci=1-$p_loci;
			$comp_aborted1="";
			$comp_aborted2="";
			$index=0;
			use bignum;
			foreach$n_hits(0..1000)
				{
				unless($index==1)
					{
					$total_prop_n_hits=0;
					foreach(1000-$n_hits..1000)
						{
						$partial_p=($factorials[1000]/($factorials[$_]*$factorials[1000-$_]))*($p_no_loci**$_)*($p_loci**(1000-$_));
						$total_prop_n_hits+=$partial_p;
						}
					if($n_hits==0)
						{
						$prob_n0=(int(($total_prop_n_hits*1000)+0.5))/1000;
						if(1-$total_prop_n_hits<$significance_piRNA_density)
							{
							$index=-1;
							}
						}
					$total_prop_n_hits=1-$total_prop_n_hits;
					if($total_prop_n_hits<$significance_piRNA_density)
						{
						$location_specific_significant_density{$chr_scaf}=$n_hits;
						$calc_01_until=$n_hits;
						$index++;
						}
					elsif($n_hits==40)
						{
						$location_specific_significant_density{$chr_scaf}=$chromosomal_piRNA_density;
						$index++;
						$comp_aborted1="> ";
						$comp_aborted2="(computation aborted)";
						}
					}
				}
			# probability chart #
			if($calc_01_until*10==0)
				{
				$calc_01_until=1;
				}
			$prob_chart=new GD::Image 300,280;
			$white=$prob_chart->colorAllocate(255,255,255);
			$black=$prob_chart->colorAllocate(0,0,0);
			$red=$prob_chart->colorAllocate(220,200,200);
			$blue=$prob_chart->colorAllocate(39,64,139);
			$green=$prob_chart->colorAllocate(155,205,155);
			$prob_chart->line(25,25,25,225,$black);
			$prob_chart->line(23,25,27,25,$black);
			$prob_chart->line(23,125,27,125,$black);
			$prob_chart->line(25,225,226,225,$black);
			$prob_chart->string(gdTinyFont,7,21,"1.0",$black);
			$prob_chart->string(gdTinyFont,7,121,"0.5",$black);
			$prob_chart->string(gdTinyFont,7,218,"0.0",$black);
			$prob_chart->string(gdMediumBoldFont,45,5,"Probability chart $chr_scaf",$black);
			$prob_chart->string(gdTinyFont,100,25,"P(n=0)=$prob_n0",$black);
			$prob_chart->string(gdTinyFont,100,35,"P exact n loci per kb",$blue);
			$prob_chart->string(gdTinyFont,100,45,"P more than n loci per kb",$green);
			$prob_chart->string(gdTinyFont,120,240,"n loci/kb",$black);
			$n_datapoints=($calc_01_until*10);
			$calc_01_until_1=$calc_01_until*0.25;
			$calc_01_until_2=$calc_01_until*0.5;
			$calc_01_until_3=$calc_01_until*0.75;
			$prob_chart->line(76,225,76,227,$black);
			$prob_chart->line(126,225,126,227,$black);
			$prob_chart->line(176,225,176,227,$black);
			$prob_chart->line(226,225,226,227,$black);
			$prob_chart->string(gdTinyFont,74,229,"$calc_01_until_1",$black);
			$prob_chart->string(gdTinyFont,124,229,"$calc_01_until_2",$black);
			$prob_chart->string(gdTinyFont,174,229,"$calc_01_until_3",$black);
			$prob_chart->string(gdTinyFont,226,229,"$calc_01_until",$black);
			@deci_probs=();
			$former_point_x=();
			$former_point_y=();
			foreach(0..($calc_01_until*10))
				{
				$hits=$_/10;
				$hits_int=int($_/10);
				$hits_dec=$hits-$hits_int;
				$fact_loci=($p_loci**$hits_int)*($p_loci**$hits_dec);
				$fact_no_loci=($p_no_loci**(1000-$hits_int))*($p_no_loci**($hits_dec));
				$partial_p=($rational_factorials{10000}/($rational_factorials{$_}*$rational_factorials{10000-$_}))*$fact_no_loci*$fact_loci;
				push(@deci_probs,((int(($partial_p*(10**100))+0.5))/(10**100)));
				# paint prob. chart, make picture #
				if($former_point_x&&$former_point_y&&$_)
					{
					$prob_chart->line(($_*(200/$n_datapoints))+26,225-($partial_p*200),$former_point_x,$former_point_y,$blue);
					open(CHART,">$result_folder_name/prob_charts/temp_chart");
					binmode CHART;
					print CHART $prob_chart->png;
					close CHART;
					$chart_pic=$mw->Photo(-format=>'png',-file=>"$result_folder_name/prob_charts/temp_chart");
					$chart_label->configure(-image=>$chart_pic);$chart_label->update;
					}
				$former_point_x=$_*(200/$n_datapoints)+26;
				$former_point_y=225-($partial_p*200);
				}
			$rest_prob=((1-$prob_n0)*$total_prop_n_hits)/(10000-$calc_01_until*10);
			foreach(($calc_01_until*10)+1..10000)
				{
				push(@deci_probs,$rest_prob);
				}
			$p_more_than_0=1-$deci_probs[0];
			@probs_final=();
			$sum_integral=0;
			foreach(@deci_probs)
				{
				$sum_integral=$sum_integral+$_;
				push(@probs_final,$sum_integral);
				}
			$former_point_x2=();
			$former_point_y2=();
			$index=0;
			foreach(1..($calc_01_until*10)+1)
				{
				$probs_final[$_]=$deci_probs[0]+(($probs_final[$_]/$sum_integral)*$p_more_than_0);
				$prob_for_point=1-$probs_final[$_];
				if($former_point_x2&&$former_point_y2)
					{
					$prob_chart->line((($_-1)*(200/$n_datapoints))+26,225-($prob_for_point*200),$former_point_x2,$former_point_y2,$green);
					open(CHART,">$result_folder_name/prob_charts/temp_chart");
					binmode CHART;
					print CHART $prob_chart->png;
					close CHART;
					$chart_pic=$mw->Photo(-format=>'png',-file=>"$result_folder_name/prob_charts/temp_chart");
					$chart_label->configure(-image=>$chart_pic);$chart_label->update;
					}
				if(1-$probs_final[$_]<=$significance_piRNA_density&&$index==0)
					{
					$index=1;
					$location_specific_significant_density{$chr_scaf}=($_/10);
					}
				$former_point_x2=($_-1)*(200/$n_datapoints)+26;
				$former_point_y2=225-($prob_for_point*200);
				}
			@deci_probs=();
			@probs_final=();
			$prob_chart=();
			rename("$result_folder_name/prob_charts/temp_chart","$result_folder_name/prob_charts/prob_chart_$save_chart.png");
			no bignum;
			$chromosomal_piRNA_density=(int(($chromosomal_piRNA_density*1000000)+0.5))/1000;while(length($chromosomal_piRNA_density)<5){$chromosomal_piRNA_density.="0";}
			$print_parameters.="$chr_scaf\t$hits_per_chromosome_or_scaffold{$chr_scaf}\t$first_last_hit_per_chromosome_or_scaffold{$chr_scaf} ($hit_comprising_range_per_chromosome_or_scaffold{$chr_scaf}bp)\t$chromosomal_piRNA_density\t$comp_aborted1$location_specific_significant_density{$chr_scaf} $comp_aborted2\n";
			$parameters_label->update;
			}
		}
	$chart_win->destroy;
	$state_of_progress.=" done.\n";
	$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
	}
else
	{
	foreach$chr_scaf(keys(%hits_per_chromosome_or_scaffold))
		{
		$location_specific_significant_density{$chr_scaf}=0;
		}
	}

###   SLIDING WINDOW OVER INPUT FILE   ###
$state_of_progress.="\nSearching proper loci density... ";
$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
$minimum_piRNAdensity_per_cluster=$minimum_piRNAdensity_per_cluster_entry/1000;
@cluster_index=();
foreach(0..$count_matches-1)
	{
	$cluster_index[$_]=0;
	}
@current_window_coord=();
@current_window_id=();
$count_lines=0;
open(INPUT,$input_file_name);
$indicate_progress=0;
while(<INPUT>)
	{
	last if $interrupt==1;
	unless($_=~/^trans_id\ttrans_coord\ttarget_seq\tprobe_id\tprobe_seq\tnum_mismatch\tstrand\n$/)
		{
		$count_lines++;
		if(($count_lines/@cluster_index)>$indicate_progress)
			{
			$indicate_progress+=0.01;
			$indicate_percent=int($indicate_progress*100);
			$state_of_progress=~s/ \d+\.*\d*%$//;
			$state_of_progress.=" $indicate_percent%";
			$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
			}
		$trans_id=$_;
		$trans_id=~s/\t.+//s;
		$trans_coord=$_;
		$trans_coord=~s/^[^\t]*\t//;
		$trans_coord=~s/\t.+//s;
		if($location_specific_significant_density{$trans_id}&&($location_specific_significant_density{$trans_id}/1000)>$minimum_piRNAdensity_per_cluster)
			{
			$minimum_piRNAdensity_per_cluster=$location_specific_significant_density{$trans_id}/1000;
			}
		push@current_window_coord,$trans_coord;
		push@current_window_id,$trans_id;
		if(@current_window_coord==$minimum_piRNA_loci_per_cluster)
			{
			if((($current_window_coord[$minimum_piRNA_loci_per_cluster-1]-$current_window_coord[0])+1)!=0) # avoid division by zero if coordinates are all the same within the sliding window
				{
				if($minimum_piRNA_loci_per_cluster/(($current_window_coord[$minimum_piRNA_loci_per_cluster-1]-$current_window_coord[0])+1)>=$minimum_piRNAdensity_per_cluster&&$current_window_id[$minimum_piRNA_loci_per_cluster-1]eq$current_window_id[0])
					{
					foreach$pos(($count_lines-$minimum_piRNA_loci_per_cluster)+1..$count_lines)
						{
						$cluster_index[$pos]=1;
						}
					}
				}
			elsif($current_window_id[$minimum_piRNA_loci_per_cluster-1]eq$current_window_id[0])
				{
				foreach$pos(($count_lines-$minimum_piRNA_loci_per_cluster)+1..$count_lines)
					{
					$cluster_index[$pos]=1;
					}
				}
			shift@current_window_coord;
			shift@current_window_id;
			}
		}
	}
close INPUT;

###   ASSEMBLE CLUSTER CANDIDATES IN TEMPORARY FILES   ###
$state_of_progress=~s/ \d+\.*\d*%$//;
$state_of_progress.="done.\nAssembling cluster candidates... ";
$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
open(INPUT,$input_file_name);
$count_lines=-1;
$cluster_label=0;
$former_state=0;
$previous_transID="";
while(<INPUT>)
	{
	$transID=$_;
	$transID=~s/\t.+$//s;
	last if $interrupt==1;
	$count_lines++;
	if($cluster_index[$count_lines]&&$cluster_index[$count_lines]==1)
		{
		unless($former_state==1)
			{
			$cluster_label++;
			open(CLUSTER_TEMP,">$result_folder_name/cluster_temp_$cluster_label");
			if($cluster_label=~/0$/)
				{
				$state_of_progress=~s/\d+$//;
				$state_of_progress.="$cluster_label";
				$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
				}
			}
		else
			{
			if($transID ne $previous_transID)
				{
				close CLUSTER_TEMP;
				$cluster_label++;
				open(CLUSTER_TEMP,">$result_folder_name/cluster_temp_$cluster_label");
				if($cluster_label=~/0$/)
					{
					$state_of_progress=~s/\d+$//;
					$state_of_progress.="$cluster_label";
					$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
					}
				}
			}
		$probe_seq=$_;
		$probe_seq=~s/^[^\t]*\t\d+\t[^\t]*\t[^\t]*\t//;
		$probe_seq=~s/\t.+//s;
		if($sequence_hash{$probe_seq}>1)
			{
			print CLUSTER_TEMP"M\t";
			}
		else
			{
			print CLUSTER_TEMP"U\t";
			}
		print CLUSTER_TEMP $_;
		}
	elsif($former_state==1)
		{
		close CLUSTER_TEMP;
		}
	$former_state=$cluster_index[$count_lines];
	$previous_transID=$transID;
	}
close INPUT;
if($consider_only_unique_mappers==1)
	{
	unlink"temp_input";
	}

$skip_gnaw=0;
$try_again_with_new_candidate=0;
###   VERIFY CLUSTER CANDIDATES   ###
$state_of_progress=~s/\d+$//;
$state_of_progress.="done ($cluster_label candidates).\nVerifying cluster candidates... 0";
$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
if($output_clustered==1)
	{
	open(ALL_CLUSTERED,">$result_folder_name/total_clustered.fas");
	}
if($output_clustered_unique==1)
	{
	open(UNIQUE_CLUSTERED,">$result_folder_name/unique_clustered.fas");
	}
if($output_clustered_multi==1)
	{
	open(MULTI_CLUSTERED,">$result_folder_name/multi_clustered.fas");
	}
if($output_summary==1)
	{
	open(SUMMARY,">$result_folder_name/proTRAC_summary.txt");
	open(SUMMARY_TEMP,">$result_folder_name/proTRAC_summary_temporary");
	print SUMMARY"$input_file_name contained $count_sequences different sequences producing $count_matches matches.\n\n";
	}
$verified_clusters=0;
$verified_pured_clusters=0;
$clustered_loci=0;
$clustered_unique=0;
$clustered_multi=0;
$tracked_mono=0;
$tracked_bi=0;
$tracked_non=0;
if($show_time==1)
	{
	@file_sizes=();
	$_elapsed_till_here=time;
	$_elapsed_till_here=$_elapsed_till_here-$start_time;
	$calc_remaining_time_0=time;
	$calc_remaining_time_1=time;
	opendir(DIR,$result_folder_name);
	$file_size_sum_initial=0;
	@files=grep(/cluster_temp/,readdir(DIR));
	closedir(DIR);
	foreach(@files)
		{
		$size=-s"$result_folder_name/$_";
		$file_size_sum_initial+=$size;
		$candidate_size_number=$_;$candidate_size_number=~s/cluster_temp_//;
		$file_sizes_check[$candidate_size_number]=$size;
		push(@file_sizes,$size);
		}
	$allready_elapsed_time=0;
	}

$estimated_remaining_time=0;
@new_candidates=();
foreach$label(1..$cluster_label)
	{
	$do_not_try_again=0; # if verification fails, try again with pured candidate
	$note_pured_candidate="(considered all reads)";
	if($show_time==1)
		{
		$calc_remaining_time_2=time;
		if($calc_remaining_time_2-$calc_remaining_time_1>0)
			{
			$calc_remaining_time_1=time;
			$file_size_sum=0;
			foreach(@file_sizes)
				{
				$file_size_sum+=$_;
				}
			$calc_remaining_time_4=time;
			$allready_elapsed_time=$calc_remaining_time_4-$calc_remaining_time_0;
			unless($file_size_sum_initial==$file_size_sum)
				{
				$estimated_remaining_time=int((($file_size_sum_initial/($file_size_sum_initial-$file_size_sum)*$allready_elapsed_time)-$allready_elapsed_time)+0.5);
				}
			$allready_elapsed_time+=$_elapsed_till_here;
			$allready_elapsed_time_hours=int($allready_elapsed_time/3600);if($allready_elapsed_time_hours<10){$allready_elapsed_time_hours="0".$allready_elapsed_time_hours;}
			$allready_elapsed_time_minutes=int(($allready_elapsed_time-$allready_elapsed_time_hours*3600)/60);if($allready_elapsed_time_minutes<10){$allready_elapsed_time_minutes="0".$allready_elapsed_time_minutes;}
			$allready_elapsed_time_seconds=$allready_elapsed_time-($allready_elapsed_time_hours*3600)-($allready_elapsed_time_minutes*60);if($allready_elapsed_time_seconds<10){$allready_elapsed_time_seconds="0".$allready_elapsed_time_seconds;}
			$estimated_remaining_time_hours=int($estimated_remaining_time/3600);if($estimated_remaining_time_hours<10){$estimated_remaining_time_hours="0".$estimated_remaining_time_hours;}
			$estimated_remaining_time_minutes=int(($estimated_remaining_time-$estimated_remaining_time_hours*3600)/60);if($estimated_remaining_time_minutes<10){$estimated_remaining_time_minutes="0".$estimated_remaining_time_minutes;}
			$estimated_remaining_time_seconds=int($estimated_remaining_time-($estimated_remaining_time_hours*3600)-($estimated_remaining_time_minutes*60));if($estimated_remaining_time_seconds<10){$estimated_remaining_time_seconds="0".$estimated_remaining_time_seconds;}
			$estimated_elapsed_string="Elapsed time:\t\t$allready_elapsed_time_hours:$allready_elapsed_time_minutes:$allready_elapsed_time_seconds\nEstimated remaining time:\t$estimated_remaining_time_hours:$estimated_remaining_time_minutes:$estimated_remaining_time_seconds\n(for verifying cluster candidates)";
			$remaining_and_elapsed_label->update;
			}
		}
	last if $interrupt==1;
	$abort_verifying_process=0;
	$state_of_progress=~s/ large candidate\. Please be patient\.//;
	$state_of_progress=~s/\d+$//;
	$state_of_progress.="$label";
	if($file_sizes_check[$label]>50000)
		{
		$state_of_progress.=" large candidate. Please be patient.";
		}
	$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
	$monodirectional=0;
	$bidirectional=0;
	$nondirectional=0;
	open(CANDIDATE,"$result_folder_name/cluster_temp_$label");
	@candidate=<CANDIDATE>;
	close CANDIDATE;
	
	verify();
	sub verify
	{
	check_loci();
	sub check_loci
		{
		$normalized_reads=0;
		$total_mappers=0;
		$unique_mappers=0;
		$multi_mappers=0;
		foreach(@candidate)
			{
			$sequence=$_;
			$sequence=~s/^[MU]\t[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t//;
			$sequence=~s/\t.+//s;
			if($_=~/^U/)
				{
				$unique_mappers++;
				$total_mappers++;
				$normalized_reads++;
				}
			elsif($_=~/^M/)
				{
				$multi_mappers++;
				$total_mappers++;
				if($FASTA_refferes_to_occurence==1)
					{
					$probe_id=$_;
					$probe_id=~s/[MU]\t[^\t]*\t\d+\t[^\t]*\t//;
					$probe_id=~s/\t.+$//s;
					$sequence_hash{$sequence}=$sequence_hash{$sequence}*$probe_id;
					}
				$normalized_reads=$normalized_reads+(1/$sequence_hash{$sequence});
				}
			}
		@plus_minus=();
		$plus=0;
		$minus=0;
		foreach(@candidate)
			{
			if($_=~/\+\n/)
				{
				$plus++;
				}
			elsif($_=~/-\n/)
				{
				$minus++;
				}
			push(@plus_minus,substr($_,-2,1));
			}
		if($unique_mappers<$minimum_unique_mappers||$normalized_reads<$minimum_normalized_reads)
			{
			$abort_verifying_process=1;
			}
		}
	
	unless($skip_gnaw==1)
	{
	#############################################################
	# GNAW UNDENSE CANDIDATE CLUSTER BORDERS
	#
	# durch das sliding window kann im index array eine reihe von 1en entstehen, die zusammengenommen
	# die erforderliche loci dichte unterschreitet. falls das so ist, werden schrittweise loci entfernt:
	# 1 vorne/hinten
	# 2 vorne+vorne/vorne+hinten/hinten+hinten
	# 3 etc.
	# die jeweiligen auswirkungen werden berechnet und für die beste möglichkeit überprüft, ob es ausreicht,
	# die dichte zu überschreiten. Falls nicht, wird ein loci mehr entfernt.
	if(@candidate>=$minimum_piRNA_loci_per_cluster&&$abort_verifying_process==0)
		{
		$cluster_start=$candidate[0];
		$cluster_start=~s/^[MU]\t[^\t]*\t//;
		$cluster_start=~s/\t.+$//s;
		$cluster_end=$candidate[-1];
		$cluster_end=~s/^[MU]\t[^\t]*\t//;
		$cluster_end=~s/\t.+$//s;
		$chr_or_scaff=$candidate[0];
		$chr_or_scaff=~s/^[MU]\t//;
		$chr_or_scaff=~s/\t.+$//s;
		if(@candidate/($cluster_end-$cluster_start+1)<($location_specific_significant_density{$chr_or_scaff})/1000||@candidate/($cluster_end-$cluster_start+1)<$minimum_piRNAdensity_per_cluster_entry/1000)
			{
			$unproper_density=1;
			foreach$loci_to_gnaw(1..($total_mappers-$minimum_piRNA_loci_per_cluster))
				{
				if($unproper_density==1)
					{
					### build array with gnaw possibilities: 1=front / 2=rear e.g. 111/112/122/222 ###
					@possibilities=();
					$possibility="";
					foreach($minimum_piRNA_loci_per_cluster..$total_mappers)
						{
						$possibility.="1";
						}
					$possibility=substr($possibility,-$loci_to_gnaw);
					push(@possibilities,$possibility);
					foreach(1..$loci_to_gnaw)
						{
						$possibility.="2";
						$possibility=substr($possibility,-$loci_to_gnaw);
						push(@possibilities,$possibility);
						}
					@current_lengths=();
					foreach$possibility(@possibilities)
						{
						@test_array=@candidate;
						$gnaw_front=($possibility=~tr/1//);
						$gnaw_rear=($possibility=~tr/2//);
						unless($gnaw_front==0)
							{
							foreach(1..$gnaw_front)
								{
								shift@test_array;
								}
							}
						unless($gnaw_rear==0)
							{
							foreach(1..$gnaw_rear)
								{
								pop@test_array;
								}
							}
						$test_cluster_start=$test_array[0];
						$test_cluster_start=~s/^[MU]\t[^\t]*\t//;
						$test_cluster_start=~s/\t.+//s;
						$test_cluster_end=$test_array[-1];
						$test_cluster_end=~s/^[MU]\t[^\t]*\t//;
						$test_cluster_end=~s/\t.+//s;
						$current_length=($test_cluster_end-$test_cluster_start)+1;
						$current_length.=".$possibility";
						push(@current_lengths,$current_length);
						}
					@sorted_current_lengths=sort{$a<=>$b}@current_lengths;
					$best_current_length_and_possibility=shift@sorted_current_lengths;
					$best_current_length=$best_current_length_and_possibility;
					$best_current_length=~s/\.\d+$//;
					$best_current_possibility=$best_current_length_and_possibility;
					$best_current_possibility=~s/^\d+\.//;
					if((($total_mappers-$loci_to_gnaw)/$best_current_length)>=$location_specific_significant_density{$chr_or_scaff}/1000&&(($total_mappers-$loci_to_gnaw)/$best_current_length)>=$minimum_piRNAdensity_per_cluster_entry/1000)
						{
						$gnaw_front=($best_current_possibility=~tr/1//);
						$gnaw_rear=($best_current_possibility=~tr/2//);
						@new_candidate_front=();
						@new_candidate_rear=();
						unless($gnaw_front==0)
							{
							foreach(1..$gnaw_front)
								{
								$new_candidate_front[-1+$_]=shift@candidate;
								}
							if($gnaw_front>1)
								{
								$cut_front_start=$new_candidate_front[0];$cut_front_start=~s/[MU]\t[^\t]*\t//;$cut_front_start=~s/\t.+$//s;
								$cut_front_end=$new_candidate_front[-1];$cut_front_end=~s/[MU]\t[^\t]*\t//;$cut_front_end=~s/\t.+$//s;
								}
							}
						unless($gnaw_rear==0)
							{
							foreach(1..$gnaw_rear)
								{
								$new_candidate_rear[-1+$_]=pop@candidate;
								}
							if($gnaw_rear>1)
								{
								$cut_rear_end=$new_candidate_rear[0];$cut_rear_end=~s/[MU]\t[^\t]*\t//;$cut_rear_end=~s/\t.+$//s; # umgekehrte reihenfolge da pop
								$cut_rear_start=$new_candidate_rear[-1];$cut_rear_start=~s/[MU]\t[^\t]*\t//;$cut_rear_start=~s/\t.+$//s;
								}
							}
						if($gnaw_front>1&&@new_candidate_front>=$minimum_piRNA_loci_per_cluster&&(@new_candidate_front/(($cut_front_end-$cut_front_start)+1))>=$location_specific_significant_density{$chr_or_scaff}/1000&&(@new_candidate_front/(($cut_front_end-$cut_front_start)+1))>=$minimum_piRNAdensity_per_cluster_entry/1000)
							{
							open(NCF,">$result_folder_name/cluster_temp_$label frontcut");
							push(@new_candidates,"$result_folder_name/cluster_temp_$label frontcut");
							foreach(@new_candidate_front){print NCF$_;}
							close NCF;
							}
						if($gnaw_rear>1&&@new_candidate_rear>=$minimum_piRNA_loci_per_cluster&&(@new_candidate_rear/(($cut_rear_end-$cut_rear_start)+1))>=$location_specific_significant_density{$chr_or_scaff}/1000&&(@new_candidate_rear/(($cut_rear_end-$cut_rear_start)+1))>=$minimum_piRNAdensity_per_cluster_entry/1000)
							{
							@new_candidate_rear=reverse@new_candidate_rear; # umgekehrte reihenfolge da pop
							open(NCR,">$result_folder_name/cluster_temp_$label rearcut");
							push(@new_candidates,"$result_folder_name/cluster_temp_$label rearcut");
							foreach(@new_candidate_rear){print NCR$_;}
							close NCR;
							}
						$unproper_density=0;
						}
					}
				}
			# actualize loci after clipping cluster borders
			check_loci();
			}
		}
	}
	
	### directionality test ###
	if(@candidate>=$minimum_piRNA_loci_per_cluster&&$abort_verifying_process==0)
		{
		$n_loci=@plus_minus; # array bestehend aus + oder - je locus
		$mono_score=$plus/$n_loci;
		if($minus/$n_loci>$mono_score)
			{
			$mono_score=$minus/$n_loci;
			}
		$directionality_for_clusterscore=$mono_score;
		if($mono_score>=$min_strand_specifity)
			{
			$monodirectional=1;
			}
		$highest_biscore=0;
		foreach$split_pos(0..$n_loci-2)
			{
			$plus1=0;$minus1=0;
			$plus2=0;$minus2=0;
			@half1=();
			@half2=@plus_minus;
			foreach(0..$split_pos)
				{
				$add_to_half1=shift@half2;
				push(@half1,$add_to_half1);
				}
			foreach$element(@half1)
				{
				if($element eq "+")
					{$plus1++;}
				else
					{$minus1++;}
				}
			foreach$element(@half2)
				{
				if($element eq "+")
					{$plus2++;}
				else
					{$minus2++;}
				}
			$n_half1=@half1;
			$n_half2=@half2;
			$both_half=@plus_minus;
			if($plus1/$n_half1>=$min_strand_specifity||$minus1/$n_half1>=$min_strand_specifity)
				{
				if($plus2/$n_half2>=$min_strand_specifity||$minus2/$n_half2>=$min_strand_specifity)
					{
					if(@half1>=(@half2/4)&&@half2>=(@half1/4)) # one half of a bidirectional cluster has to comprise at least 25% of all loci
						{
						bidirectional_cluster();
						sub bidirectional_cluster
							{
							$biscore_half1=$plus1/$n_half1;
							if($minus1/$n_half1>$biscore_half1)
								{
								$biscore_half1=$minus1/$n_half1;
								}
							$biscore_half1=$biscore_half1*$n_half1;
							
							$biscore_half2=$plus2/$n_half2;
							if($minus2/$n_half2>$biscore_half2)
								{
								$biscore_half2=$minus2/$n_half2;
								}
							$biscore_half2=$biscore_half2*$n_half2;
							$biscore=($biscore_half1+$biscore_half2)/$both_half;
							if($biscore>$mono_score&&$biscore>$highest_biscore)
								{
								$bidirectional=1;
								$monodirectional=0;
								$highest_biscore=$biscore;
								$directionality_for_clusterscore=$biscore;
								}
							}
						}
					elsif(@half1>=10&&@half2>=10) # or at least 10 loci
						{
						bidirectional_cluster();
						}
					}
				}
			}
		if($monodirectional+$bidirectional==0)
			{
			$nondirectional=1;
			}
		$save_this_cluster=0;
		if($do_monodirectional==1&&$monodirectional==1)
			{
			$save_this_cluster=1;
			$folder_to_save="monodirectional_clusters";
			}
		elsif($do_bidirectional==1&&$bidirectional==1)
			{
			$save_this_cluster=1;
			$folder_to_save="bidirectional_clusters";
			}
		elsif($do_nondirectional==1&&$nondirectional==1)
			{
			$save_this_cluster=1;
			$folder_to_save="nondirectional_clusters";
			}
		if($do_monodirectional==0&&$monodirectional==1)
			{
			$abort_verifying_process=1;
			}
		elsif($do_bidirectional==0&&$bidirectional==1)
			{
			$abort_verifying_process=1;
			}
		elsif($do_nondirectional==0&&$nondirectional==1)
			{
			$abort_verifying_process=1;
			}
		}
	
	####################################
	##########   FINAL VERIFICATION    #########
	####################################
	if(@candidate>=$minimum_piRNA_loci_per_cluster&&$abort_verifying_process==0)
		{
		$cluster_start=$candidate[0];
		$cluster_start=~s/^[MU]\t[^\t]*\t//;
		$cluster_start=~s/\t.+$//s;
		$cluster_end=$candidate[-1];
		$chromosome=$cluster_end;
		$cluster_end=~s/^[MU]\t[^\t]*\t//;
		$cluster_end=~s/\t.+$//s;
		$chromosome=~s/^[MU]\t//;
		$chromosome=~s/\t.+$//s;
		$size=$cluster_end-$cluster_start+1;
		$loci_density=$total_mappers/$size*1000;
		if($skip_gnaw==1)
			{
			$size=abs($size);
			}
		
		# % 1U-loci, 10A-loci / % inside length optimum #
		$U_absolute=0;
		$not_U_absolute=0;
		$yes_10A_absolute=0;
		$not_10A_absolute=0;
		$length_inside_optimum=0;
		$length_outside_optimum=0;
		foreach(@candidate)
			{
			$check_for_U=$_;
			$check_for_U=~s/^[MU]\t[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t//;
			$check_length_of_loci=$check_for_U;
			$check_length_of_loci=~s/\t.+//s;
			if(substr($check_for_U,0,1)eq"T")
				{
				$U_absolute++;
				}
			else
				{
				$not_U_absolute++;
				}
			if(substr($check_for_U,9,1)eq"A")
				{
				$yes_10A_absolute++;
				}
			else
				{
				$not_10A_absolute++;
				}
			if((length$check_length_of_loci)>=$desired_length_minimum&&(length$check_length_of_loci)<=$desired_length_maximum)
				{
				$length_inside_optimum++;
				}
			else
				{
				$length_outside_optimum++;
				}
			}
		$rate_of_U=$U_absolute/($U_absolute+$not_U_absolute);
		$rate_of_10A=$yes_10A_absolute/($yes_10A_absolute+$not_10A_absolute);
		$rate_of_optimum_length=$length_inside_optimum/($length_inside_optimum+$length_outside_optimum);
		if($rate_of_U*100<$minimum_U_loci||$rate_of_10A*100<$minimum_10A_loci||$rate_of_optimum_length*100<$minimum_desired_length_loci)
			{
			$abort_verifying_process=1;
			}

		#############################
		#   calculate probabilistic piRNA cluster scores   #
		#############################
			use bignum;
			### if n loci > factorial limit ###
			unless($abort_verifying_process==1)
				{
				$overrun=0;
				$optional_star='';
				if($total_mappers>$factorial_limit)
					{
					$overrun=1;
					$save1=$total_mappers;
					$save2=$n_mainstrand_loci;
					$save3=$U_absolute;
					$save4=$yes_10A_absolute;
					$save5=$length_inside_optimum;
					$save6=$normalized_reads;
					$breakdown_factor=$total_mappers/$factorial_limit;
					$total_mappers=$factorial_limit;
					$n_mainstrand_loci=$n_mainstrand_loci/$breakdown_factor;
					$U_absolute=$U_absolute/$breakdown_factor;
					$yes_10A_absolute=$yes_10A_absolute/$breakdown_factor;
					$length_inside_optimum=$length_inside_optimum/$breakdown_factor;
					$seqs_outside_opt=$seqs_outside_opt/$breakdown_factor;
					$normalized_reads=$normalized_reads/$breakdown_factor;
					}
				}
			
			# directionality
			if($minimum_strand_bias>0&&$abort_verifying_process==0)
				{
				$n_mainstrand_loci=$directionality_for_clusterscore*$n_loci;
				$total_prop_directionality=0;
				$factor2=0.5**$total_mappers;
				foreach$ms_loci($n_mainstrand_loci..$total_mappers)
					{
					$partial_p=($factorials[$total_mappers]/($factorials[$total_mappers-$ms_loci]*$factorials[$ms_loci]))*$factor2;
					$total_prop_directionality+=$partial_p;
					}
				$total_prop_directionality=1/($total_prop_directionality*2); # p ++/-- = 0.5 not 0.25
				if($total_prop_directionality>10**100)
					{$score_directionality=100;}
				else
					{no bignum;$score_directionality=(int(((log($total_prop_directionality)/log(10))*10)+0.5))/10;use bignum;}
				}
			else
				{
				$score_directionality=0;
				}
			if($score_directionality<$minimum_strand_bias)
				{
				$abort_verifying_process=1;
				}

			# 1T
			if($minimum_enrichment_for_1T_OR_10_A_loci>0&&$abort_verifying_process==0)
				{
				if($assume_random_basecomposition==1)
					{
					$T1_ratio_dataset=0.25;
					$A10_ratio_dataset=0.25;
					}
				$total_prop_1T=0;
				if($U_absolute>=$total_mappers/2)
					{
					foreach$T_loci($U_absolute..$total_mappers)
						{
						$partial_p=($factorials[$total_mappers]/($factorials[$total_mappers-$T_loci]*$factorials[$T_loci]))*($T1_ratio_dataset**$T_loci)*($V1_ratio_dataset**($total_mappers-$T_loci));
						$total_prop_1T+=$partial_p;
						}
					$total_prop_1T=1/$total_prop_1T;
					}
				else
					{
					foreach$T_loci(0..$U_absolute-1)
						{
						$partial_p=($factorials[$total_mappers]/($factorials[$total_mappers-$T_loci]*$factorials[$T_loci]))*($T1_ratio_dataset**$T_loci)*($V1_ratio_dataset**($total_mappers-$T_loci));
						$total_prop_1T+=$partial_p;
						}
					$total_prop_1T=1-$total_prop_1T;
					$total_prop_1T=1/$total_prop_1T;
					}
				if($total_prop_1T>10**100)
					{$score_1T=100;}
				else
					{no bignum;$score_1T=(int(((log($total_prop_1T)/log(10))*10)+0.5))/10;use bignum;}

			# 10A
				$total_prop_10A=0;
				if($yes_10A_absolute>=$total_mappers/2)
					{
					foreach$A_loci($yes_10A_absolute..$total_mappers)
						{
						$partial_p=($factorials[$total_mappers]/($factorials[$total_mappers-$A_loci]*$factorials[$A_loci]))*($A10_ratio_dataset**$A_loci)*($B10_ratio_dataset**($total_mappers-$A_loci));
						$total_prop_10A+=$partial_p;
						}
					$total_prop_10A=1/$total_prop_10A;
					}
				else
					{
					foreach$A_loci(0..$yes_10A_absolute-1)
						{
						$partial_p=($factorials[$total_mappers]/($factorials[$total_mappers-$A_loci]*$factorials[$A_loci]))*($A10_ratio_dataset**$A_loci)*($B10_ratio_dataset**($total_mappers-$A_loci));
						$total_prop_10A+=$partial_p;
						}
					$total_prop_10A=1-$total_prop_10A;
					$total_prop_10A=1/$total_prop_10A;
					}
				if($total_prop_10A>10**100)
					{$score_10A=100;}
				else
					{no bignum;$score_10A=(int(((log($total_prop_10A)/log(10))*10)+0.5))/10;use bignum;}
				}
			else{$score_1T=0;$score_10A=0;}
			if($score_1T<$minimum_enrichment_for_1T_OR_10_A_loci&&$score_10A<$minimum_enrichment_for_1T_OR_10_A_loci)
				{
				$abort_verifying_process=1;
				}

			# percent reads with optimum length
			if($minimum_enrichment_for_loci_with_optimal_length>0&&$abort_verifying_process==0)
				{
				$total_prop_optimal_length=0;
				if($length_inside_optimum>=$total_mappers/2)
					{
					foreach$optimal_length_loci($length_inside_optimum..$total_mappers)
						{
						$partial_p=($factorials[$total_mappers]/($factorials[$total_mappers-$optimal_length_loci]*$factorials[$optimal_length_loci]))*($seqs_inside_opt**$optimal_length_loci)*($seqs_outside_opt**($total_mappers-$optimal_length_loci));
						$total_prop_optimal_length+=$partial_p;
						}
					$total_prop_optimal_length=1/$total_prop_optimal_length;
					}
				else
					{
					foreach$optimal_length_loci(0..$length_inside_optimum-1)
						{
						$partial_p=($factorials[$total_mappers]/($factorials[$total_mappers-$optimal_length_loci]*$factorials[$optimal_length_loci]))*($seqs_inside_opt**$optimal_length_loci)*($seqs_outside_opt**($total_mappers-$optimal_length_loci));
						$total_prop_optimal_length+=$partial_p;
						}
					$total_prop_optimal_length=1-$total_prop_optimal_length;
					$total_prop_optimal_length=1/$total_prop_optimal_length;
					}
				if($total_prop_optimal_length>10**100)
					{$score_optimal_length=100;}
				else
					{no bignum;$score_optimal_length=(int(((log($total_prop_optimal_length)/log(10))*10)+0.5))/10;use bignum;}
				}
			else{$score_optimal_length=0}
			if($score_optimal_length<$minimum_enrichment_for_loci_with_optimal_length)
				{
				$abort_verifying_process=1;
				}
			
			# ratio of normalized reads vs. total reads
			if($minimum_enrichment_for_rare_loci>0&&$abort_verifying_process==0)
				{
				$total_prop_group1=0;
				$total_prop_group2=0;
				$total_prop_group3=0;
				$total_prop_group4=0;
				if($normalized_reads/$total_mappers<=$average_group5)
					{
					$score_normal_vs_total=0;
					}
				else
					{
					$found_minimum_group1=0;
					$found_minimum_group2=0;
					$found_minimum_group3=0;
					$found_minimum_group4=0;
					foreach(1..$total_mappers)
						{
						if(($_+(($total_mappers-$_)*$average_group2_3_4_5))/$total_mappers>($normalized_reads/$total_mappers))
							{
							$found_minimum_group1=1;
							$partial_p_minimum_group1=($factorials[$total_mappers]/($factorials[$total_mappers-$_]*$factorials[$_]))*(($group1/$count_matches)**$_)*((($group2_3_4_5)/$count_matches)**($total_mappers-$_));
							$total_prop_group1+=$partial_p_minimum_group1;
							}
						if($found_minimum_group1==1)
							{
							if((($_*$average_group2)+(($total_mappers-$_)*$average_group3_4_5))/$total_mappers>($normalized_reads/$total_mappers))
								{
								$found_minimum_group2=1;
								$partial_p_minimum_group2=($factorials[$total_mappers]/($factorials[$total_mappers-$_]*$factorials[$_]))*(($group2/$count_matches)**$_)*((($group3_4_5)/$count_matches)**($total_mappers-$_));
								$total_prop_group2+=$partial_p_minimum_group2;
								}
							}
						if($found_minimum_group2==1)
							{
							if((($_*$average_group3)+(($total_mappers-$_)*$average_group4_5))/$total_mappers>($normalized_reads/$total_mappers))
								{
								$found_minimum_group3=1;
								$partial_p_minimum_group3=($factorials[$total_mappers]/($factorials[$total_mappers-$_]*$factorials[$_]))*(($group3/$count_matches)**$_)*((($group4_5)/$count_matches)**($total_mappers-$_));
								$total_prop_group3+=$partial_p_minimum_group3;
								}
							}
						if($found_minimum_group3==1)
							{
							if((($_*$average_group4)+(($total_mappers-$_)*$average_group5))/$total_mappers>($normalized_reads/$total_mappers))
								{
								$found_minimum_group4=1;
								$partial_p_minimum_group4=($factorials[$total_mappers]/($factorials[$total_mappers-$_]*$factorials[$_]))*(($group4/$count_matches)**$_)*(($group5/$count_matches)**($total_mappers-$_));
								$total_prop_group4+=$partial_p_minimum_group4;
								}
							}
						}
					$total_prop_normal_vs_total=1/($total_prop_group1+$total_prop_group2+$total_prop_group3+$total_prop_group4);
					if($total_prop_normal_vs_total>10**100)
						{$score_normal_vs_total=100;}
					else
						{no bignum;$score_normal_vs_total=(int(((log($total_prop_normal_vs_total)/log(10))*10)+0.5))/10;use bignum;}
					}
				}
			else{$score_normal_vs_total=0;}
			if($score_normal_vs_total<$minimum_enrichment_for_rare_loci)
				{
				$abort_verifying_process=1;
				}

			# total cluster score
			$total_cluster_score=$score_directionality+$score_1T+$score_10A+$score_optimal_length+$score_normal_vs_total;
			if($score_1T>$score_10A)
				{$T1_OR_10_A_score=$score_1T;}
			else
				{$T1_OR_10_A_score=$score_10A;}
			
			unless($total_cluster_score=~/\./)
				{$total_cluster_score.=".0";}
			no bignum;
			if($overrun==1)
				{
				$total_mappers=$save1;
				$n_mainstrand_loci=$save2;
				$U_absolute=$save3;
				$yes_10A_absolute=$save4;
				$length_inside_optimum=$save5;
				$normalized_reads=$save6;
				$optional_star='*';
				}

		############################################
		#   agreement absolute minimum requirements + minimum probabilistic scores  #
		############################################
		
		if($normalized_reads>=$minimum_normalized_reads&&$rate_of_U>=$minimum_U_loci_relative&&$rate_of_10A>=$minimum_10A_loci_relative&&$rate_of_optimum_length>=$minimum_desired_length_loci_relative&&$unique_mappers>=$minimum_unique_mappers&&$size<=$maximum_size_per_cluster&&$size>=$minimum_size_per_cluster&&$total_mappers/$size>=$minimum_piRNAdensity_per_cluster_entry/1000&&$total_mappers/$size>=$location_specific_significant_density{$chromosome}/1000&&$save_this_cluster==1)
			{
			if($score_directionality>=$minimum_strand_bias&&$score_normal_vs_total>=$minimum_enrichment_for_rare_loci&&$score_optimal_length>=$minimum_enrichment_for_loci_with_optimal_length&&$T1_OR_10_A_score>=$minimum_enrichment_for_1T_OR_10_A_loci)
				{
				# p that all prob. parameters occured not by chance #
				use bignum;
				@cluster_scores=();
				if($minimum_strand_bias>0){push(@cluster_scores,$score_directionality);}
				if($minimum_enrichment_for_1T_OR_10_A_loci>0){push(@cluster_scores,$T1_OR_10_A_score);}
				if($minimum_enrichment_for_loci_with_optimal_length>0){push(@cluster_scores,$score_optimal_length);}
				if($minimum_enrichment_for_rare_loci>0){push(@cluster_scores,$score_normal_vs_total);}
				@cluster_scores_pre0=();
				foreach(@cluster_scores)
					{
					if($_=~/^\d+$/)
						{
						$_.=".0"
						}
					@score=split(/\./,$_);
					$exponent="1";
					foreach(1..$score[0])
						{
						$exponent.="0";
						}
					$score[1]="0.$score[1]";
					$score[1]=10**$score[1];
					$p0=1-(1/($score[1]*$exponent));
					push(@cluster_scores_pre0,$p0);
					}
				$p_sum_0=1;
				foreach(@cluster_scores_pre0)
					{
					$p_sum_0=$p_sum_0*$_;
					}
				$p_sum_1=1-$p_sum_0;
				push(@cluster_scores0,$p_sum_0);
				push(@cluster_scores1,$p_sum_1);
				no bignum;
				###  summary output   ###
				if($monodirectional==1)
					{
					$tracked_mono++;
					$summary_directionality="mono-directional";
					}
				if($bidirectional==1)
					{
					$tracked_bi++;
					$summary_directionality="bi-directional";
					}
				if($nondirectional==1)
					{
					$tracked_non++;
					$summary_directionality="non-directional";
					}
				$verified_clusters++;
				if($skip_gnaw==1)
					{
					$verified_new_clusters++;
					}
				if($do_not_try_again==1&&$try_again_with_new_candidate==0)
					{
					$verified_pured_clusters++;
					}
				if($do_not_try_again==1&&$try_again_with_new_candidate==1)
					{
					$verified_pured_new_clusters++;
					}
				if($output_summary==1)
					{
					$rate_of_U=($rate_of_U*100)+0.005;
					if($rate_of_U<10){$rate_of_U=substr($rate_of_U,0,4);}
					else{$rate_of_U=substr($rate_of_U,0,5)};
					$rate_of_10A=($rate_of_10A*100)+0.005;
					if($rate_of_10A<10){$rate_of_10A=substr($rate_of_10A,0,4);}
					else{$rate_of_10A=substr($rate_of_10A,0,5)};
					$rate_of_optimum_length=($rate_of_optimum_length*100)+0.005;
					if($rate_of_optimum_length<10){$rate_of_optimum_length=substr($rate_of_optimum_length,0,4);}
					else{$rate_of_optimum_length=substr($rate_of_optimum_length,0,5)};
					$loci_density=(int(($loci_density*10000)+0.5))/10000;
					$directionality_for_clusterscore=($directionality_for_clusterscore*100)+0.005;
					$directionality_for_clusterscore=substr($directionality_for_clusterscore,0,5);
					$ratio_normalized_total=$normalized_reads/$total_mappers;
					$total_cluster_score="000".$total_cluster_score;
					$total_cluster_score=substr($total_cluster_score,-6);
					print SUMMARY_TEMP"$total_cluster_score Cluster $verified_clusters\tLoci: $total_mappers\tnormalized: $normalized_reads, normalized/total: $ratio_normalized_total, multi: $multi_mappers, unique: $unique_mappers, plus: $plus, minus: $minus, 1T(U): $U_absolute ($rate_of_U%), 10A: $yes_10A_absolute ($rate_of_10A%), optimum length: $length_inside_optimum ($rate_of_optimum_length%)\t$summary_directionality ($directionality_for_clusterscore%)\tLoci/1000bp: $loci_density\tLocation: $chromosome\tCoordinates: $cluster_start-$cluster_end ($size bp)";
					if($total_cluster_score=~/^0+$/)
						{$total_cluster_score="0";}
					else
						{$total_cluster_score=~s/^0+//;}
					print SUMMARY_TEMP"\tCluster score: $total_cluster_score$optional_star (D: $score_directionality 1T: $score_1T 10A: $score_10A OL: $score_optimal_length NTR: $score_normal_vs_total)";
					}
				###   visualization   ###
				if($do_visualization==1)
					{
					$image=new GD::Image $picture_width,$picture_height;
					$white=$image->colorAllocate(255,255,255);
					$black=$image->colorAllocate(0,0,0);
					$red=$image->colorAllocate(205,38,38);
					$green=$image->colorAllocate(155,205,155);
					$image->line(100,($picture_height/2),($picture_width-100),($picture_height/2),$black);
					$image->line(100,($picture_height-20),100,20,$black);
					$one="1";
					foreach$decimal(2..length$cluster_start)
						{
						$one=" ".$one;
						}
					$image->string(gdSmallFont,2,2,"Cluster $verified_clusters / $chromosome",$black);
					$image->string(gdTinyFont,50,(($picture_height/2)-9),"$one",$black);
					$image->string(gdTinyFont,50,(($picture_height/2)+2),"$cluster_start",$black);
					$image->string(gdTinyFont,($picture_width-90),(($picture_height/2)-9),"$size",$black);
					$image->string(gdTinyFont,($picture_width-90),(($picture_height/2)+2),"$cluster_end",$black);
					$image->string(gdSmallFont,40,(($picture_height/2)-32),"+ strand",$black);
					$image->string(gdSmallFont,40,(($picture_height/2)+18),"- strand",$black);
					}
				open(VERIFIED,">$result_folder_name/$folder_to_save/Cluster_$verified_clusters.fas");
				$sum_of_transcription=0;
				foreach(@candidate)
					{
					$coordinate=$_;
					$coordinate=~s/^[MU]\t[^\t]*\t//;
					$coordinate=~s/\t.+//s;
					$sequence=$_;
					$sequence=~s/^[MU]\t[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t//;
					$sequence=~s/\t.+//s;
					$probe_id=$_;
					$probe_id=~s/^[MU]\t[^\t]*\t[^\t]*\t[^\t]*\t//;
					$probe_id=~s/\t.+//s;
					$multimap_or_uniquemap=substr($_,0,1);
					$plus_or_minus=substr($_,-2,1);
					print VERIFIED ">$chromosome $coordinate $probe_id $multimap_or_uniquemap $plus_or_minus\n$sequence\n";
					if($output_clustered==1)
						{
						if($transcription_cutoff_all)
							{
							if($probe_id>=$transcription_cutoff_all)
								{
								print ALL_CLUSTERED ">$chromosome $coordinate $probe_id $multimap_or_uniquemap $plus_or_minus\n$sequence\n";
								}
							}
						else
							{
							print ALL_CLUSTERED ">$chromosome $coordinate $probe_id $multimap_or_uniquemap $plus_or_minus\n$sequence\n";
							}
						}
					if($output_clustered_unique==1&&$multimap_or_uniquemap eq "U")
						{
						if($transcription_cutoff_unique)
							{
							if($probe_id>=$transcription_cutoff_unique)
								{
								print UNIQUE_CLUSTERED ">$chromosome $coordinate $probe_id $multimap_or_uniquemap $plus_or_minus\n$sequence\n";
								}
							}
						else
							{
							print UNIQUE_CLUSTERED ">$chromosome $coordinate $probe_id $multimap_or_uniquemap $plus_or_minus\n$sequence\n";
							}
						}
					if($output_clustered_multi==1&&$multimap_or_uniquemap eq "M")
						{
						if($transcription_cutoff_multi)
							{
							if($probe_id>=$transcription_cutoff_multi)
								{
								print MULTI_CLUSTERED ">$chromosome $coordinate $probe_id $multimap_or_uniquemap $plus_or_minus\n$sequence\n";
								}
							}
						else
							{
							print MULTI_CLUSTERED ">$chromosome $coordinate $probe_id $multimap_or_uniquemap $plus_or_minus\n$sequence\n";
							}
						}
					if($do_visualization==1)
						{
						$color=$black;
						$bar_heigth=20;
						if($indicate_transcription_rate==1&&$FASTA_refferes_to_occurence==1)
							{
							$bar_heigth=$pixel_for_one_transcript*$probe_id;
							if($bar_heigth>(($picture_height/2)-20))
								{
								$color=$green;
								$bar_heigth=(($picture_height/2)-20);
								}
							}
						if($plus_or_minus eq "-")
							{
							$bar_heigth=$bar_heigth*-1;
							}
						if($multimap_or_uniquemap eq "M")
							{
							if($accent_multiple_mappers==1)
								{
								$color=$red;
								}
							if($normalize_multiple_mappers==1&&$indicate_transcription_rate==1)
								{
								if($FASTA_refferes_to_occurence==1)
									{
									$sequence_hash{$sequence}=$sequence_hash{$sequence}*$probe_id;
									}
								$bar_heigth=$bar_heigth/$sequence_hash{$sequence};
								}
							}
						$loci_position=(($coordinate-$cluster_start)/$size)*($picture_width-200);
						$loci_position=$loci_position+101;
						$image->line($loci_position,($picture_height/2),$loci_position,(($picture_height/2)-$bar_heigth),$color);
						}
					if($FASTA_refferes_to_occurence==1)
						{
						if($normalize_multiple_mappers==1)
							{
							$probe_id=$probe_id/($sequence_hash{$sequence}*$probe_id);
							}
						$sum_of_transcription=$sum_of_transcription+$probe_id;
						}
					}
				if($FASTA_refferes_to_occurence==1&&$calculate_average_transcription==1&&$output_summary==1)
					{
					$transcription_per_loci=$sum_of_transcription/$total_mappers;
					print SUMMARY_TEMP"\taverage transcription per loci: $transcription_per_loci\t*$note_pured_candidate\n";
					}
				elsif($output_summary==1)
					{
					print SUMMARY_TEMP"\t*$note_pured_candidate\n";
					}
				close VERIFIED;
				if($do_visualization==1)
					{
					open (IMAGE,">$result_folder_name/$folder_to_save/Cluster_$verified_clusters.png");
					binmode IMAGE;
					print IMAGE $image->png;
					close IMAGE;
					$image=();
					}
				$clustered_loci=$clustered_loci+$total_mappers;
				$clustered_unique=$clustered_unique+$unique_mappers;
				$clustered_multi=$clustered_multi+$multi_mappers;
				}
			elsif($do_not_try_again==0&&$do_reconsideration==1)
				{
				repeat_with_infrequently_mapping_reads();
				}
			}
		elsif($do_not_try_again==0&&$do_reconsideration==1)
			{
			repeat_with_infrequently_mapping_reads();
			}
		}
	}
	unlink "$result_folder_name/cluster_temp_$label";
	shift@file_sizes;
	}

### repeat verification with infrequently mapping reads ###
sub repeat_with_infrequently_mapping_reads
	{
	if($label)
		{
		$note_pured_candidate="(considered reads with less than $frequently_threshold loci)";
		$do_not_try_again=1; # to exit loop once the pured candidate failed to be verified
		unless($try_again_with_new_candidate==1)
			{
			open(CANDIDATE,"$result_folder_name/cluster_temp_$label");
			@candidate=<CANDIDATE>;
			close CANDIDATE;
			}
		@pured_candidate=();
		foreach(@candidate)
			{
			last if $interrupt==1;
			$sequence=$_;
			$sequence=~s/^[MU]\t[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t//;
			$sequence=~s/\t.+//s;
			if($FASTA_refferes_to_occurence==1)
				{
				$probe_id=$_;
				$probe_id=~s/[MU]\t[^\t]*\t\d+\t[^\t]*\t//;
				$probe_id=~s/\t.+$//s;
				$sequence_hash{$sequence}=$sequence_hash{$sequence}*$probe_id;
				}
			if($sequence_hash{$sequence}<=$frequently_threshold)
				{
				push(@pured_candidate,$_);
				}
			}
		@candidate=@pured_candidate;
		if(@candidate>=$minimum_piRNA_loci_per_cluster)
			{
			$abort_verifying_process=0;
			$monodirectional=0;
			$bidirectional=0;
			$nondirectional=0;
			verify();
			}
		}
	}

### verify new candidates resulting from gnawed cluster borders ###
$aditional_candidates=@new_candidates;
$state_of_progress.=" done.\nChecking removed loci ($aditional_candidates aditional candidates)... ";
$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
$skip_gnaw=1;
$verified_new_clusters=0;
$verified_pured_new_clusters=0;
$count_aditional=0;
$do_not_try_again=0;
$try_again_with_new_candidate=1;
foreach$new_candidate_filename(@new_candidates)
	{
	$do_not_try_again=0;
	last if $interrupt==1;
	$count_aditional++;
	$state_of_progress.="$count_aditional";
	$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
	$abort_verifying_process=0;
	unless(open(NEW_CANDIDATE,$new_candidate_filename))
		{
		print"could not open $new_candidate_filename\n";
		}
	else
		{
		@candidate=<NEW_CANDIDATE>;
		close NEW_CANDIDATE;
		$monodirectional=0;
		$bidirectional=0;
		$nondirectional=0;
		verify();
		unlink $new_candidate_filename;
		}
	$state_of_progress=~s/\d+$//;
	}
$state_of_progress.=" done. ($verified_new_clusters aditional clusters)";
$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;

#########################################

$results_directionality="";
if($do_monodirectional==1)
	{$results_directionality.="Mono-directional clusters: $tracked_mono\n";}
if($do_bidirectional==1)
	{$results_directionality.="Bi-directional clusters: $tracked_bi\n";}
if($do_nondirectional==1)
	{$results_directionality.="Non-directional clusters: $tracked_non\n";}
$state_of_progress=~s/\d+$//;
$state_of_progress.="\n\nTracked clusters: $verified_clusters\n$results_directionality"."Total clustered loci: $clustered_loci (multiple: $clustered_multi, unique: $clustered_unique)\n";

###   CALCULATE P TO GET FALSE POSITIVE CLUSTERS   ###
$state_of_progress.="\nValidating results... ";
$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
use bignum;
# build possible combinations of 1 false positive cluster in $verified clusters
@possibility_strings=();
$pos_of_1=-1;
foreach$string_id(0..$verified_clusters-1)
	{
	$pos_of_1++;
	foreach(0..$verified_clusters-1)
		{
		unless($_==$pos_of_1)
			{
			$possibility_strings[$string_id].="0";
			}
		else
			{
			$possibility_strings[$string_id].="1";
			}
		}
	}
# compute p
$total_p_for_0=1;
foreach(@cluster_scores0)
	{
	last if $interrupt==1;
	$total_p_for_0=$total_p_for_0*$_;
	}
$total_p_for_0=(int(($total_p_for_0*1000000000000000)+0.5))/1000000000000000;
$state_of_progress.="\nP 0 false positive* hits: $total_p_for_0\n";
$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;

$total_p_for_1=0;

$time_est_validate_00=time;
$time_est_validate_0=time;
$processed_strings=0;
foreach(@possibility_strings)
	{
	last if $interrupt==1;
	$processed_strings++;
	$count_p=-1;
	@split_pos=split('',$_);
	$p_for_1=1;
	foreach$split_pos(@split_pos)
		{
		last if $interrupt==1;
		$count_p++;
		if($split_pos==0)
			{$p_for_1=$p_for_1*$cluster_scores0[$count_p];}
		elsif($split_pos==1)
			{$p_for_1=$p_for_1*$cluster_scores1[$count_p];}
		if($show_time==1)
			{
			$time_est_validate_1=time;
			if($time_est_validate_1-$time_est_validate_0>0)
				{
				$time_est_validate_0=time;
				$est_rem_time_validate=(($time_est_validate_1-$time_est_validate_00)/$processed_strings)*(@possibility_strings-$processed_strings);
				$allready_elapsed_time=$time_est_validate_1-$start_time;
				$allready_elapsed_time_hours=int($allready_elapsed_time/3600);if($allready_elapsed_time_hours<10){$allready_elapsed_time_hours="0".$allready_elapsed_time_hours;}
				$allready_elapsed_time_minutes=int(($allready_elapsed_time-$allready_elapsed_time_hours*3600)/60);if($allready_elapsed_time_minutes<10){$allready_elapsed_time_minutes="0".$allready_elapsed_time_minutes;}
				$allready_elapsed_time_seconds=$allready_elapsed_time-($allready_elapsed_time_hours*3600)-($allready_elapsed_time_minutes*60);if($allready_elapsed_time_seconds<10){$allready_elapsed_time_seconds="0".$allready_elapsed_time_seconds;}
				$estimated_remaining_time_hours=int($est_rem_time_validate/3600);if($estimated_remaining_time_hours<10){$estimated_remaining_time_hours="0".$estimated_remaining_time_hours;}
				$estimated_remaining_time_minutes=int(($est_rem_time_validate-$estimated_remaining_time_hours*3600)/60);if($estimated_remaining_time_minutes<10){$estimated_remaining_time_minutes="0".$estimated_remaining_time_minutes;}
				$estimated_remaining_time_seconds=int($est_rem_time_validate-($estimated_remaining_time_hours*3600)-($estimated_remaining_time_minutes*60));if($estimated_remaining_time_seconds<10){$estimated_remaining_time_seconds="0".$estimated_remaining_time_seconds;}
				$estimated_elapsed_string="Elapsed time:\t\t$allready_elapsed_time_hours:$allready_elapsed_time_minutes:$allready_elapsed_time_seconds\nEstimated remaining time:\t$estimated_remaining_time_hours:$estimated_remaining_time_minutes:$estimated_remaining_time_seconds\n(for validation of results)";
				$remaining_and_elapsed_label->update;
				}
			}
		}
	$total_p_for_1+=$p_for_1;
	}
$total_p_for_1=(int(($total_p_for_1*1000000000000000)+0.5))/1000000000000000;
$total_p_for_1_or_more=(1-$total_p_for_0);
$state_of_progress.="P 1 or more false positive* hits: $total_p_for_1_or_more\n";
$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;

$total_p_for_2=1-($total_p_for_1+$total_p_for_0);
$total_p_for_2=substr($total_p_for_2,0,50);
$state_of_progress.="P 2 or more false positive* hits: $total_p_for_2\n* Definition false positive hit:\nRegarding a certain cluster, score for one or more probabilistic\nparameter stated >0 came off by chance.";
$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
@cluster_scores_pre0=();
@cluster_scores0=();
@cluster_scores1=();
no bignum;

###   FINISH OUTPUT SUMMARY   ###
if($output_summary==1)
	{
	close SUMMARY_TEMP;
	open(SUMMARY_TEMP,"$result_folder_name/proTRAC_summary_temporary");
	@list_of_clusters=<SUMMARY_TEMP>;
	close SUMMARY_TEMP;
	unlink"$result_folder_name/proTRAC_summary_temporary";
	if($sort_summary_by_score==1)
		{
		@list_of_clusters=sort(@list_of_clusters);
		@list_of_clusters=reverse(@list_of_clusters);
		}
	foreach(@list_of_clusters)
		{
		$_=substr($_,7);
		print SUMMARY"$_";
		}
	@list_of_clusters=();
	print SUMMARY"\nTotal clustered loci: $clustered_loci (multi: $clustered_multi,unique: $clustered_unique)\n\n";
	unless($interrupt==1)
		{print SUMMARY"P 0 false positive hits: $total_p_for_0\nP 1 or more false positive hits: $total_p_for_1_or_more\nP 2 or more false positive hits: $total_p_for_2";}
	else
		{print SUMMARY"P 0 false positive hits: ?\nP 1 or more false positive hits: ?\nP 2 or more false positive hits: ?";}
	close SUMMARY;
	}
close ALL_CLUSTERED;
close UNIQUE_CLUSTERED;
close MULTI_CLUSTERED;

###   CLUSTER PREVIEW IN GUI   ###
sub refresh_preview
	{
	fasta_referres_to_occurence();
	@example_coordinates=(1450,1530,1600,1780,1846,1899,1930,2094,2100,2105,2300,3410,3533,3590,3709,4020,4100,4304,4509,4530,4600,4780,4846,4899,4930,6070,6140,6180,6340,6350,6370,6395,7010,12400,12480,12540,13120,13250,13450,13723,13934,14300,14390,14690,15900,16740,17840,17912,17999,18200,18319,18422,18523,18588,18599,19020,19090,19140,19323,19400,19467,19580,19730,20000,20100,22222,22300,24980,25000);
	@example_probe_ids=(1,1,2,1,1,2,2,1,1,4,1,1,6,1,1,3,1,9,4,1,1,1,1,1,1,1,1,2,1,1,1,1,4,1,7,5,8,1,5,9,6,8,2,13,8,6,7,5,9,6,1,3,4,2,1,1,1,2,1,1,3,1,1,1,2,1,4,1,1);
	@example_plus_or_minus=("-","-","-","-","+","-","-","-","-","-","-","-","-","-","+","-","-","-","-","-","-","-","-","-","-","-","-","-","-","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","+","-","+","+","+","+","+","-","+","+","+","+","+","+");
	@example_multimap_or_uniquemap=("U","U","U","M","U","M","U","U","U","M","U","U","U","M","M","M","U","U","U","U","U","M","U","U","U","U","U","U","U","U","U","U","U","U","U","M","U","U","U","U","U","U","U","U","U","M","U","U","U","U","U","U","U","U","U","U","U","U","M","U","U","M","U","U","U","U","U","U","U","U");
	@example_sequence_frequencies=(3,5,6,3,6,7,4,5,7,4,9,3,6,1,6,3,4,9,6,8,7,2,6,4,3,6,5,4,5,3,8,3,4,1,6,4,5,2,8,6,3,5,6,3,6,7,4,5,7,4,9,3,6,1,6,3,4,9,6,8,7,2,6,4,3,6,5,4,5,3,8,3,4,1,6,4,5,2,8);
	$cluster_start=1577432;	
	$cluster_end=1602377;
	$size=($cluster_end-$cluster_start)+1;
	
	$preview=new GD::Image $picture_width,$picture_height;
	$white=$preview->colorAllocate(255,255,255);
	$black=$preview->colorAllocate(0,0,0);
	$red=$preview->colorAllocate(205,38,38);
	$green=$preview->colorAllocate(155,205,155);
	$preview->line(100,($picture_height/2),($picture_width-100),($picture_height/2),$black);
	$preview->line(100,($picture_height-20),100,20,$black);
	$one="1";
	foreach$decimal(2..length$cluster_start)
		{
		$one=" ".$one;
		}
	$preview->string(gdSmallFont,2,2,"Cluster 1 / Chr1",$black);
	$preview->string(gdTinyFont,50,(($picture_height/2)-9),"$one",$black);
	$preview->string(gdTinyFont,50,(($picture_height/2)+2),"$cluster_start",$black);
	$preview->string(gdTinyFont,($picture_width-90),(($picture_height/2)-9),"$size",$black);
	$preview->string(gdTinyFont,($picture_width-90),(($picture_height/2)+2),"$cluster_end",$black);
	$preview->string(gdSmallFont,40,(($picture_height/2)-32),"+ strand",$black);
	$preview->string(gdSmallFont,40,(($picture_height/2)+18),"- strand",$black);
	foreach(0..68)
		{
		$coordinate=$example_coordinates[$_];
		$probe_id=$example_probe_ids[$_];
		$multimap_or_uniquemap=$example_multimap_or_uniquemap[$_];
		$plus_or_minus=$example_plus_or_minus[$_];
		$color=$black;
		$bar_heigth=20;
		if($indicate_transcription_rate==1&&$FASTA_refferes_to_occurence==1)
			{
			$bar_heigth=$pixel_for_one_transcript*$probe_id;
			if($bar_heigth>(($picture_height/2)-20))
				{
				$color=$green;
				$bar_heigth=(($picture_height/2)-20);
				}
			}
		if($plus_or_minus eq "-")
			{
			$bar_heigth=$bar_heigth*-1;
			}
		if($multimap_or_uniquemap eq "M")
			{
			if($accent_multiple_mappers==1)
				{
				$color=$red;
				}
			if($normalize_multiple_mappers==1&&$indicate_transcription_rate==1)
				{
				$bar_heigth=$bar_heigth/$example_sequence_frequencies[$_];
				}
			}
		$loci_position=($coordinate/$size)*($picture_width-200);
		$loci_position=$loci_position+101;
		$preview->line($loci_position,($picture_height/2),$loci_position,(($picture_height/2)-$bar_heigth),$color);
		}
	open(IMAGE,">proTRAC_files/prev_temp");
	binmode IMAGE;
	print IMAGE $preview->png;
	close IMAGE;
	$preview_image=$mw->Photo(-format=>'png',-file=>"proTRAC_files/prev_temp");
	}

###   THE END   ###
$end_time=time;
$computation_time=$end_time-$start_time;
$hours=int($computation_time/3600);
$minutes=int(($computation_time-$hours*3600)/60);
$seconds=$computation_time-($hours*3600)-($minutes*60);
$state_of_progress.="\n\nElapsed time: $hours hours, $minutes minutes, $seconds seconds";
if($interrupt==1)
	{
	$button_stop->configure(-state=>'disabled');
	$state_of_progress.="\nTRACKING WAS TERMINATED!";
	$print_parameters="TRACKING WAS TERMINATED!";
	$parameters_label->update;
	foreach$label(1..$cluster_label)
		{
		unlink"$result_folder_name/cluster_temp_$label";
		}
	}
$progress_label->update;$progress_pane->yview(moveto=>1);$progress_pane->update;
if($consider_only_unique_mappers==1)
	{$input_file_name=$input_file_name_original;}

# re-/activate widgets
$view_cses->configure(-state=>'normal');
if($output_summary==1)
	{$summary_available=1;}
elsif($output_summary==0)
	{$summary_available=0;}
foreach(@widgets)		
	{
	$_->configure(-state=>'normal');
	}
$button_stop->configure(-state=>'disabled');
if($fasta_eq_occ_variable eq"NO")
	{
	$cb_normalize->configure(-background=>grey90,-state=>'disabled');
	$cb_indicate->configure(-background=>grey90,-state=>'disabled');
	$entry_pixel->configure(-background=>grey90,-state=>'disabled');
	$cb_average->configure(-background=>grey90,-state=>'disabled');
	$entry_cutoff_all->configure(-background=>grey90,-state=>'disabled');
	$entry_cutoff_unique->configure(-background=>grey90,-state=>'disabled');
	$entry_cutoff_multi->configure(-background=>grey90,-state=>'disabled');
	}

# time reset
if($show_time==1)
	{
	$button_clock->configure(-state=>'disabled');
	if($hours<10){$hours="0".$hours;}if($minutes<10){$minutes="0".$minutes;}if($seconds<10){$seconds="0".$seconds;}
	$estimated_elapsed_string="Elapsed time:\t\t$hours:$minutes:$seconds\nEstimated remaining time:\t00:00:00";
	$remaining_and_elapsed_label->update;
	}
else
	{
	$button_noclock->configure(-state=>'disabled');
	}
}
$input_file_name="";
###   RATIONAL FACTORIALS FOR SIGNIFICANT DENSITY   ###
sub rational_factorials
	{
	use bignum;
	$rational_factorials{0}=1;
	$rational_factorials{1}=0.95135076986687318362924871772654;
	$rational_factorials{2}=0.91816874239976061064095165518583;
	$rational_factorials{3}=0.89747069630627718849375495477148;
	$rational_factorials{4}=0.88726381750307528922362160876307;
	$rational_factorials{5}=0.88622692545275801364908374167057;
	$rational_factorials{6}=0.89351534928769026143660003299281;
	$rational_factorials{7}=0.90863873285329044997681982540697;
	$rational_factorials{8}=0.93138377098024269890905675061477;
	$rational_factorials{9}=0.96176583190738741940757480212503;
	$rational_factorials{10}=1;
	$rational_factorials{11}=1.0464858468535605019921735894992;
	$rational_factorials{12}=1.101802490879712732769141986223;
	$rational_factorials{13}=1.1667119051981603450418814412029;
	$rational_factorials{14}=1.2421693445043054049130702522683;
	$rational_factorials{15}=1.3293403881791370204736256125059;
	$rational_factorials{16}=1.4296245588603044182985600527885;
	$rational_factorials{17}=1.5446858458505937649605937031918;
	$rational_factorials{18}=1.6764907877644368580363021511066;
	$rational_factorials{19}=1.8273550806240360968743921240376;
	$rational_factorials{20}=2;
	$rational_factorials{21}=2.1976202783924770541835645379483;
	$rational_factorials{22}=2.4239654799353680120921123696906;
	$rational_factorials{23}=2.6834373819557687935963273147667;
	$rational_factorials{24}=2.9812064268103329717913686054439;
	$rational_factorials{25}=3.3233509704478425511840640312646;
	$rational_factorials{26}=3.7170238530367914875762561372501;
	$rational_factorials{27}=4.170651783796603165393602998618;
	$rational_factorials{28}=4.6941742057404232025016460230984;
	$rational_factorials{29}=5.2993297338097046809357371597089;
	$rational_factorials{30}=6;
	$rational_factorials{31}=6.8126228630166788679690500676398;
	$rational_factorials{32}=7.7566895357931776386947595830099;
	$rational_factorials{33}=8.8553433604540370188678801387301;
	$rational_factorials{34}=10.136101851155132104090653258509;
	$rational_factorials{35}=11.631728396567448929144224109426;
	$rational_factorials{36}=13.3812858709324493552745220941;
	$rational_factorials{37}=15.431411600047431711956331094887;
	$rational_factorials{38}=17.837861981813608169506254887774;
	$rational_factorials{39}=20.667385961857848255649374922865;
	$rational_factorials{40}=24;
	$rational_factorials{41}=27.931753738368383358673105277323;
	$rational_factorials{42}=32.578096050331346082517990248642;
	$rational_factorials{43}=38.07797644995235918113188459654;
	$rational_factorials{44}=44.598848145082581257998874337441;
	$rational_factorials{45}=52.342777784553520181149008492418;
	$rational_factorials{46}=61.553915006289267034262801632861;
	$rational_factorials{47}=72.527634520222929046194756145967;
	$rational_factorials{48}=85.621737512705319213630023461315;
	$rational_factorials{49}=101.27019121310345645268193712204;
	$rational_factorials{50}=120;
	$rational_factorials{51}=142.45194406567875512923283691435;
	$rational_factorials{52}=169.40609946172299962909354929294;
	$rational_factorials{53}=201.81327518474750365999898836166;
	$rational_factorials{54}=240.83377998344593879319392142218;
	$rational_factorials{55}=287.8852778150443609963195467083;
	$rational_factorials{56}=344.70192403521989539187168914402;
	$rational_factorials{57}=413.40751676527069556331011003201;
	$rational_factorials{58}=496.60607757369085143905413607563;
	$rational_factorials{59}=597.49412815731039307082342902002;
	$rational_factorials{60}=720;
	$rational_factorials{61}=868.95685880064040628832030517752;
	$rational_factorials{62}=1050.3178166626825977003800056162;
	$rational_factorials{63}=1271.4236336639092730579936266785;
	$rational_factorials{64}=1541.336191894054008276441097102;
	$rational_factorials{65}=1871.254305797788346476077053604;
	$rational_factorials{66}=2275.0326986324513095863531483505;
	$rational_factorials{67}=2769.8303623273136602741777372145;
	$rational_factorials{68}=3376.9213275010977897855681253143;
	$rational_factorials{69}=4122.7094842854417121886816602382;
	$rational_factorials{70}=5040;
	$rational_factorials{71}=6169.5936974845468846470741667604;
	$rational_factorials{72}=7562.2882799713147034427360404367;
	$rational_factorials{73}=9281.3925257465376933233534747527;
	$rational_factorials{74}=11405.887820015999661245664118555;
	$rational_factorials{75}=14034.40729348341259857057790203;
	$rational_factorials{76}=17290.248509606629952856283927464;
	$rational_factorials{77}=21327.693789920315184111168576551;
	$rational_factorials{78}=26339.986354508562760327431377451;
	$rational_factorials{79}=32569.404925854989526290585115881;
	$rational_factorials{80}=40320;
	$rational_factorials{81}=49973.708949624829765641300750759;
	$rational_factorials{82}=62010.763895764780568230435531581;
	$rational_factorials{83}=77035.557963696262854583833840448;
	$rational_factorials{84}=95809.457688134397154463578595858;
	$rational_factorials{85}=119292.46199460900708784991216725;
	$rational_factorials{86}=148696.13718261701759456404177619;
	$rational_factorials{87}=185550.935972306742101767166616;
	$rational_factorials{88}=231791.87991967535229088139612157;
	$rational_factorials{89}=289867.70384010940678398620753134;
	$rational_factorials{90}=362880;
	$rational_factorials{91}=454760.75144158595086733583683191;
	$rational_factorials{92}=570499.02784103598122772000689054;
	$rational_factorials{93}=716430.68906237524454762965471616;
	$rational_factorials{94}=900608.90226846333325195763880107;
	$rational_factorials{95}=1133278.3889487855673345741655889;
	$rational_factorials{96}=1427482.9169531233689078148010514;
	$rational_factorials{97}=1799844.0789313753983871415161752;
	$rational_factorials{98}=2271560.4232128184524506376819914;
	$rational_factorials{99}=2869690.2680170831271614634545603;
	$rational_factorials{100}=3628800;
	$rational_factorials{101}=4593083.5895600181037600919520023;
	$rational_factorials{102}=5819090.0839785670085227440702835;
	$rational_factorials{103}=7379236.0973424650188405854435765;
	$rational_factorials{104}=9366332.5835920186658203594435311;
	$rational_factorials{105}=11899423.083962248457013028738683;
	$rational_factorials{106}=15131318.919703107710422836891145;
	$rational_factorials{107}=19258331.644565716762742414223074;
	$rational_factorials{108}=24532852.570698439286466886965507;
	$rational_factorials{109}=31279623.921386206086059951654707;
	$rational_factorials{110}=39916800;
	$rational_factorials{111}=50983227.844116200951737020667225;
	$rational_factorials{112}=65173808.940559950495454733587176;
	$rational_factorials{113}=83385367.899969854712898615512414;
	$rational_factorials{114}=106776191.45294901279035209765625;
	$rational_factorials{115}=136843365.46556585725564983049486;
	$rational_factorials{116}=175523299.46855604944090490793729;
	$rational_factorials{117}=225322480.24141888612408624640997;
	$rational_factorials{118}=289487660.33424158358030926619298;
	$rational_factorials{119}=372227524.66449585242411342469102;
	$rational_factorials{120}=479001600;
	$rational_factorials{121}=616897056.91380603151601795007342;
	$rational_factorials{122}=795120469.07483139604454774976354;
	$rational_factorials{123}=1025640025.1696292129686529708027;
	$rational_factorials{124}=1324024774.0165677586003660109376;
	$rational_factorials{125}=1710542068.3195732156956228811857;
	$rational_factorials{126}=2211593573.3038062229554018400098;
	$rational_factorials{127}=2861595499.0660198537758953294066;
	$rational_factorials{128}=3705442052.2782922698279586072702;
	$rational_factorials{129}=4801735068.1719964962710631785141;
	$rational_factorials{130}=6227020800;
	$rational_factorials{131}=8081351445.5708590128598351459619;
	$rational_factorials{132}=10495590191.787774427788030296879;
	$rational_factorials{133}=13641012334.756068532483084511676;
	$rational_factorials{134}=17741931971.822007965244904546563;
	$rational_factorials{135}=23092317922.314238411890908896007;
	$rational_factorials{136}=30077672596.931764632193465024133;
	$rational_factorials{137}=39203858337.204471996729766012871;
	$rational_factorials{138}=51135100321.440433323625828780329;
	$rational_factorials{139}=66744117447.590751298167778181346;
	$rational_factorials{140}=87178291200;
	$rational_factorials{141}=113947055382.54911208132367555806;
	$rational_factorials{142}=149037380723.38639687459003021568;
	$rational_factorials{143}=195066476387.01178001450810851696;
	$rational_factorials{144}=255483820394.23691469952662547051;
	$rational_factorials{145}=334838609873.55645697241817899211;
	$rational_factorials{146}=439134019915.20376363002458935234;
	$rational_factorials{147}=576296717556.9057383519275603892;
	$rational_factorials{148}=756799484757.31841318966226594887;
	$rational_factorials{149}=994487349969.10219434269989490206;
	$rational_factorials{150}=1307674368000;
	$rational_factorials{151}=1720600536276.4915924279875009267;
	$rational_factorials{152}=2265368186995.4732324937684592783;
	$rational_factorials{153}=2984517088721.2802342219740603096;
	$rational_factorials{154}=3934450834071.2484863727100322459;
	$rational_factorials{155}=5189998453040.1250830724817743777;
	$rational_factorials{156}=6850490710677.1787126283835938966;
	$rational_factorials{157}=9047858465643.4200921252626981104;
	$rational_factorials{158}=11957431859165.630928396663801992;
	$rational_factorials{159}=15812348864508.724890048928328943;
	$rational_factorials{160}=20922789888000;
	$rational_factorials{161}=27701668634051.514638090598764921;
	$rational_factorials{162}=36698964629326.666366399049040309;
	$rational_factorials{163}=48647628546156.867817818177183046;
	$rational_factorials{164}=64524993678768.475176512444528832;
	$rational_factorials{165}=85634974475162.063870695949277231;
	$rational_factorials{166}=113718145797241.16662963116765868;
	$rational_factorials{167}=151099236376245.11553849188705844;
	$rational_factorials{168}=200884855233982.59959706395187347;
	$rational_factorials{169}=267228695810197.45064182688875913;
	$rational_factorials{170}=355687428096000;
	$rational_factorials{171}=473698533642280.90031134923888014;
	$rational_factorials{172}=631222191624418.66150206364349331;
	$rational_factorials{173}=841603973848513.81324825446526669;
	$rational_factorials{174}=1122734890010571.4680713165348017;
	$rational_factorials{175}=1498612053315336.1177371791123516;
	$rational_factorials{176}=2001439366031444.5326815085507928;
	$rational_factorials{177}=2674456483859538.5450313064009345;
	$rational_factorials{178}=3575750423164890.2728277383433477;
	$rational_factorials{179}=4783393655002534.3664887013087885;
	$rational_factorials{180}=6402373705728000;
	$rational_factorials{181}=8573943458925284.2956354212237305;
	$rational_factorials{182}=11488243887564419.639337558311578;
	$rational_factorials{183}=15401352721427802.78244305671438;
	$rational_factorials{184}=20658321976194515.012512224240351;
	$rational_factorials{185}=27724322986333718.178137813578504;
	$rational_factorials{186}=37226772208184868.307876059044747;
	$rational_factorials{187}=50012336248173370.792085429697474;
	$rational_factorials{188}=67224107955499937.129161480854937;
	$rational_factorials{189}=90406140079547899.526636454736102;
	$rational_factorials{190}=121645100408832000;
	$rational_factorials{191}=163762320065472930.04663654537325;
	$rational_factorials{192}=220574282641236857.0752811195823;
	$rational_factorials{193}=297246107523556593.70115099458754;
	$rational_factorials{194}=400771446338173591.24273715026281;
	$rational_factorials{195}=540624298233507504.47368736478082;
	$rational_factorials{196}=729644735280423418.83437075727703;
	$rational_factorials{197}=985243024089015404.60408296504025;
	$rational_factorials{198}=1331037337518898755.1573973209278;
	$rational_factorials{199}=1799082187583003200.5800654492484;
	$rational_factorials{200}=2432902008176640000;
	$rational_factorials{201}=3291622633316005893.9373945620024;
	$rational_factorials{202}=4455600509352984512.9206786155625;
	$rational_factorials{203}=6034095982728198852.1333651901271;
	$rational_factorials{204}=8175737505298741261.3518378653613;
	$rational_factorials{205}=11082798113786903841.710590978007;
	$rational_factorials{206}=15030681546776722427.988037599907;
	$rational_factorials{207}=20394530598642618875.304517376333;
	$rational_factorials{208}=27685576620393094107.273864275297;
	$rational_factorials{209}=37600817720484766892.123367889292;
	$rational_factorials{210}=51090942171709440000;
	$rational_factorials{211}=69453237562967724362.079025258251;
	$rational_factorials{212}=94458730798283271673.918386649925;
	$rational_factorials{213}=128526244432110635550.44067854971;
	$rational_factorials{214}=174960782613393062992.92933031873;
	$rational_factorials{215}=238280159446418432596.77770602715;
	$rational_factorials{216}=324662721410377204444.54161215799;
	$rational_factorials{217}=442561313990544829594.10802706643;
	$rational_factorials{218}=603545570324569451538.57024120148;
	$rational_factorials{219}=823457908078616394937.5017567755;
	$rational_factorials{220}=1124000727777607680000;
	$rational_factorials{221}=1534916550141586708401.9464582073;
	$rational_factorials{222}=2096983823721888631160.9881836283;
	$rational_factorials{223}=2866135250836067172774.8271316585;
	$rational_factorials{224}=3919121530540004611041.6169991396;
	$rational_factorials{225}=5361303587544414733427.4983856108;
	$rational_factorials{226}=7337377503874524820446.6404347705;
	$rational_factorials{227}=10046141827585367631786.252214408;
	$rational_factorials{228}=13760839003400183495079.401499394;
	$rational_factorials{229}=18857186095000315444068.790230159;
	$rational_factorials{230}=25852016738884976640000;
	$rational_factorials{231}=35456572308270652964084.963184589;
	$rational_factorials{232}=48650024710347816242934.925860177;
	$rational_factorials{233}=66780951344480365125653.472167643;
	$rational_factorials{234}=91707443814636107898373.837779866;
	$rational_factorials{235}=125990634307293746235546.21206185;
	$rational_factorials{236}=173162109091438785762540.71426058;
	$rational_factorials{237}=238093561313773212873334.17748147;
	$rational_factorials{238}=327507968280924367182889.75568557;
	$rational_factorials{239}=450686747670507539113244.0865008;
	$rational_factorials{240}=620448401733239439360000;
	$rational_factorials{241}=854503392629322736434447.61274861;
	$rational_factorials{242}=1177330597990417153079025.2058163;
	$rational_factorials{243}=1622777117670872872553379.3736737;
	$rational_factorials{244}=2237661629077121032720321.6418287;
	$rational_factorials{245}=3086770540528696782770882.1955154;
	$rational_factorials{246}=4259787883649394129758501.5708104;
	$rational_factorials{247}=5880910964450198357971354.1837922;
	$rational_factorials{248}=8122197613366924306135665.9410022;
	$rational_factorials{249}=11222100016995637723919777.75387;
	$rational_factorials{250}=15511210043330985984000000;
	$rational_factorials{251}=21448035154996000684504635.07999;
	$rational_factorials{252}=29668731069358512257591435.186571;
	$rational_factorials{253}=41056261077073083675600498.153945;
	$rational_factorials{254}=56836605378558874231096169.70245;
	$rational_factorials{255}=78712648783481767960657495.985643;
	$rational_factorials{256}=109050569821424489721817640.21275;
	$rational_factorials{257}=151139411786370097799863802.52346;
	$rational_factorials{258}=209552698424866647098300181.27786;
	$rational_factorials{259}=290652390440187017049522243.82523;
	$rational_factorials{260}=403291461126605635584000000;
	$rational_factorials{261}=559793717545395617865570975.58774;
	$rational_factorials{262}=777320754017193021148895601.88815;
	$rational_factorials{263}=1079779666327022100668293101.4488;
	$rational_factorials{264}=1500486381993954279700938880.1447;
	$rational_factorials{265}=2085885192762266850957423643.6195;
	$rational_factorials{266}=2900745157249891426600349229.659;
	$rational_factorials{267}=4035422294696081611256363527.3764;
	$rational_factorials{268}=5616012317786426142234444858.2465;
	$rational_factorials{269}=7818549302841030758632148358.8987;
	$rational_factorials{270}=10888869450418352160768000000;
	$rational_factorials{271}=15170409745480221244156973438.428;
	$rational_factorials{272}=21143124509267650175249960371.358;
	$rational_factorials{273}=29477984890727703348244401669.551;
	$rational_factorials{274}=41113326866634347263805725315.964;
	$rational_factorials{275}=57361842800962338401329150199.538;
	$rational_factorials{276}=80060566340097003374169638738.589;
	$rational_factorials{277}=111781197563081460631801269708.33;
	$rational_factorials{278}=156125142434462646754117567059.25;
	$rational_factorials{279}=218137525549264758165836939213.27;
	$rational_factorials{280}=304888344611713860501504000000;
	$rational_factorials{281}=426288513847994216960810953619.82;
	$rational_factorials{282}=596236111161347734942048882472.28;
	$rational_factorials{283}=834226972407594004755316567248.29;
	$rational_factorials{284}=1167618483012415462292082598973.4;
	$rational_factorials{285}=1634812519827426644437880780686.8;
	$rational_factorials{286}=2289732197326774296501251667923.7;
	$rational_factorials{287}=3208120370060437920132696440629;
	$rational_factorials{288}=4496404102112524226518585931306.5;
	$rational_factorials{289}=6304174488373751510992687543263.6;
	$rational_factorials{290}=8841761993739701954543616000000;
	$rational_factorials{291}=12404995752976631713559598750337;
	$rational_factorials{292}=17410094445911353860307827368191;
	$rational_factorials{293}=24442850291542504339330775420375;
	$rational_factorials{294}=34327983400565014591387228409817;
	$rational_factorials{295}=48226969334909086010917483030261;
	$rational_factorials{296}=67776073040872519176437049370540;
	$rational_factorials{297}=95281174990795006227941084286680;
	$rational_factorials{298}=1.3399284224295322195025386075293*(10**32);
	$rational_factorials{299}=1.8849481720237517017868135754358*(10**32);
	$rational_factorials{300}=2.6525285981219105863630848*(10**32);
	$rational_factorials{301}=3.7339037216459661457814392238514*(10**32);
	$rational_factorials{302}=5.2578485226652288658129638651936*(10**32);
	$rational_factorials{303}=7.4061836383373788148172249523736*(10**32);
	$rational_factorials{304}=1.0435706953771764435781717436584*(10**33);
	$rational_factorials{305}=1.470922564714727123332983232423*(10**33);
	$rational_factorials{306}=2.0739478350506990867989737107385*(10**33);
	$rational_factorials{307}=2.9251320722174066911977912876011*(10**33);
	$rational_factorials{308}=4.1269795410829592360678189111904*(10**33);
	$rational_factorials{309}=5.8244898515533927585212539480967*(10**33);
	$rational_factorials{310}=8.22283865417792281772556288*(10**33);
	$rational_factorials{311}=1.1612440574318954713380275986178*(10**34);
	$rational_factorials{312}=1.6404487390715514061336447259404*(10**34);
	$rational_factorials{313}=2.3181354787995995690377914100929*(10**34);
	$rational_factorials{314}=3.2768119834843340328354592750875*(10**34);
	$rational_factorials{315}=4.6334060788513904384988971821323*(10**34);
	$rational_factorials{316}=6.5536751587602091142847569259338*(10**34);
	$rational_factorials{317}=9.2726686689291792110969983816954*(10**34);
	$rational_factorials{318}=1.3123794940643810370695664137585*(10**35);
	$rational_factorials{319}=1.8580122626455322899682800094428*(10**35);
	$rational_factorials{320}=2.6313083693369353016721801216*(10**35);
	$rational_factorials{321}=3.7275934243563844629950685915631*(10**35);
	$rational_factorials{322}=5.2822449398103955277503360175281*(10**35);
	$rational_factorials{323}=7.4875775965227066079920662546002*(10**35);
	$rational_factorials{324}=1.0616870826489242266386888051284*(10**36);
	$rational_factorials{325}=1.505856975626701892512141584193*(10**36);
	$rational_factorials{326}=2.1364981017558281712568307578544*(10**36);
	$rational_factorials{327}=3.0321626547398416020287184708144*(10**36);
	$rational_factorials{328}=4.304604740531169801588177837128*(10**36);
	$rational_factorials{329}=6.112860344103801233995641231067*(10**36);
	$rational_factorials{330}=8.68331761881188649551819440128*(10**36);
	$rational_factorials{331}=1.2338334234619632572513677038074*(10**37);
	$rational_factorials{332}=1.7537053200170513152131115578193*(10**37);
	$rational_factorials{333}=2.4933633396420613004613580627819*(10**37);
	$rational_factorials{334}=3.5460348560474069169732206091287*(10**37);
	$rational_factorials{335}=5.0446208683494513399156743070466*(10**37);
	$rational_factorials{336}=7.1786336218995826554229513463908*(10**37);
	$rational_factorials{337}=1.0218388146473266198836781246645*(10**38);
	$rational_factorials{338}=1.4549564022995353929368041089493*(10**38);
	$rational_factorials{339}=2.0722596566511886183245223773317*(10**38);
	$rational_factorials{340}=2.9523279903960414084761860964352*(10**38);
	$rational_factorials{341}=4.2073719740052947072271638699831*(10**38);
	$rational_factorials{342}=5.9976721944583154980288415277421*(10**38);
	$rational_factorials{343}=8.5522362549722702605824581553418*(10**38);
	$rational_factorials{344}=1.2198359904803079794387878895403*(10**39);
	$rational_factorials{345}=1.7403941995805607122709076359311*(10**39);
	$rational_factorials{346}=2.4838072331772555987763411658512*(10**39);
	$rational_factorials{347}=3.5457806868262233709963630925857*(10**39);
	$rational_factorials{348}=5.0632482800023831674200782991434*(10**39);
	$rational_factorials{349}=7.2321862017126482779525830968876*(10**39);
	$rational_factorials{350}=1.0333147966386144929666651337523*(10**40);
	$rational_factorials{351}=1.4767875628758584422367345183641*(10**40);
	$rational_factorials{352}=6.1783994085109905285617221075553*(10**40);
	$rational_factorials{353}=3.0189393980052114019856077288357*(10**40);
	$rational_factorials{354}=4.3182194063002902472133091289726*(10**40);
	$rational_factorials{355}=6.1783994085109905285617221075553*(10**40);
	$rational_factorials{356}=8.8423537501110299316437745504303*(10**40);
	$rational_factorials{357}=1.2658437051969617434457016240531*(10**41);
	$rational_factorials{358}=1.8126428842408531739363880310933*(10**41);
	$rational_factorials{359}=2.5963548464148407317849773317827*(10**41);
	$rational_factorials{360}=3.7199332678990121746799944815084*(10**41);
	$rational_factorials{361}=5.3312031019818489764746116112943*(10**41);
	$rational_factorials{362}=7.6424738170665639402082710283101*(10**41);
	$rational_factorials{363}=1.0958750014758917389207756055673*(10**42);
	$rational_factorials{364}=1.571831863893305649985644522946*(10**42);
	$rational_factorials{365}=2.2551157841065115429250285692577*(10**42);
	$rational_factorials{366}=3.2363014725406369549816214854575*(10**42);
	$rational_factorials{367}=4.6456463980728495984457249602748*(10**42);
	$rational_factorials{368}=6.6705258140063396800859079544235*(10**42);
	$rational_factorials{369}=9.580549383270762300286566354278*(10**42);
	$rational_factorials{370}=1.3763753091226345046315979581581*(10**43);
	$rational_factorials{371}=1.9778763508352659702720809077902*(10**43);
	$rational_factorials{372}=2.8430002599487617857574768225314*(10**43);
	$rational_factorials{373}=4.0876137555050761861744930087662*(10**43);
	$rational_factorials{374}=5.8786511709609631309463105158181*(10**43);
	$rational_factorials{375}=8.4566841903994182859688571347163*(10**43);
	$rational_factorials{376}=1.216849353675279495073089678532*(10**44);
	$rational_factorials{377}=1.7514086920734642986140383100236*(10**44);
	$rational_factorials{378}=2.5214587576943963990724732067721*(10**44);
	$rational_factorials{379}=3.6310282162596189118086086482714*(10**44);
	$rational_factorials{380}=5.2302261746660111176000722410007*(10**44);
	$rational_factorials{381}=7.5357088966823633467366282586806*(10**44);
	$rational_factorials{382}=1.086026099300427002159356146207*(10**45);
	$rational_factorials{383}=1.5655560683584441793048308223575*(10**45);
	$rational_factorials{384}=2.2574020496490098422833832380742*(10**45);
	$rational_factorials{385}=4.6970385051865788509821261591336*(10**45);
	$rational_factorials{387}=6.7779516383243068356363282597913*(10**45);
	$rational_factorials{388}=9.7832599798542580284011960422757*(10**45);
	$rational_factorials{389}=1.4124699761249917566935487641776*(10**46);
	$rational_factorials{390}=2.0397882081197443358640281739903*(10**46);
	$rational_factorials{391}=2.9464621786028040685740216491441*(10**46);
	$rational_factorials{392}=4.2572223092576738484646760931314*(10**46);
	$rational_factorials{393}=6.1526353486486856246679851318648*(10**46);
	$rational_factorials{394}=8.8941640756170987785965299580122*(10**46);
	$rational_factorials{395}=1.286050248254991535838713948762*(10**47);
	$rational_factorials{396}=1.8600272480538852249889219590169*(10**47);
	$rational_factorials{397}=2.6908468004147498137476223191372*(10**47);
	$rational_factorials{398}=3.8937374719819946953036760248257*(10**47);
	$rational_factorials{399}=5.6357552047387171092072595690685*(10**47);
	$rational_factorials{400}=8.1591528324789773434561126959612*(10**47);
	$rational_factorials{10000}=4.0238726007709377354370243392300*(10**2567);
	$rational_factorials{9999}=2.0166228392809760591922818703332*(10**2567);
	$rational_factorials{9998}=1.0106702500338985452638050778991*(10**2567);
	$rational_factorials{9997}=5.0652236300075453207983839077345*(10**2566);
	$rational_factorials{9996}=2.5385873321183783879618064507906*(10**2566);
	$rational_factorials{9995}=1.2723011956950554641822441803774*(10**2566);
	$rational_factorials{9994}=6.3766430237371231534515641693966*(10**2565);
	$rational_factorials{9993}=3.1959400060447325848786674362223*(10**2565);
	$rational_factorials{9992}=1.6018043734728308674651810276814*(10**2565);
	$rational_factorials{9991}=8.0283200298572654102808295775016*(10**2564);
	$rational_factorials{9990}=4.0238726007709377354370243392300*(10**2564);
	$rational_factorials{9989}=2.0168245217331493741296948398172*(10**2564);
	$rational_factorials{9988}=1.0108724245188023057249500679127*(10**2564);
	$rational_factorials{9987}=5.0667436531034763637074961565815*(10**2563);
	$rational_factorials{9986}=2.5396031733877334813543481900666*(10**2563);
	$rational_factorials{9985}=1.2729376645273191237441162384967*(10**2563);
	$rational_factorials{9984}=6.3804713065210357749165140778433*(10**2562);
	$rational_factorials{9983}=3.1981787311565421643937430563617*(10**2562);
	$rational_factorials{9982}=1.6030868429471886183598689228197*(10**2562);
	$rational_factorials{9981}=8.0355520266812785609857167225519*(10**2561);
	$rational_factorials{9980}=4.0279005012722099453824067459760*(10**2561);
	$rational_factorials{9979}=2.0190454717520766584539942334740*(10**2561);
	$rational_factorials{9978}=1.0120869288334023885912595794080*(10**2561);
	$rational_factorials{9977}=5.0733389937954103972238872099544*(10**2560);
	$rational_factorials{9976}=2.5431636024311370732569078610721*(10**2560);
	$rational_factorials{9975}=1.2748499394364738344958600285395*(10**2560);
	$rational_factorials{9974}=6.3906964207943066655814443888655*(10**2559);
	$rational_factorials{9973}=3.2036248934754504301249554806789*(10**2559);
	$rational_factorials{9972}=1.6059776026319260853134331024040*(10**2559);
	$rational_factorials{9971}=8.0508486390955601252236416416710*(10**2558);
	$rational_factorials{9970}=4.0359724461645390234292652765291*(10**2558);
	$rational_factorials{9969}=2.0232943899710157916163886496382*(10**2558);
	$rational_factorials{9968}=1.0143184293780340635310278406574*(10**2558);
	$rational_factorials{9967}=5.0850345733140326723703389896306*(10**2557);
	$rational_factorials{9966}=2.5492818789405945000570447685166*(10**2557);
	$rational_factorials{9965}=1.2780450520666404355848220837489*(10**2557);
	$rational_factorials{9964}=6.4073555452118574950686228081667*(10**2556);
	$rational_factorials{9963}=3.2122980983409710519652616872344*(10**2556);
	$rational_factorials{9962}=1.6104869661371099932946581452106*(10**2556);
	$rational_factorials{9961}=8.0742640047092168541005331879160*(10**2555);
	$rational_factorials{9960}=4.0481167965542016283142079002298*(10**2555);
	$rational_factorials{9959}=2.0295861069024132727619506967983*(10**2555);
	$rational_factorials{9958}=1.0175746683166473350030375608522*(10**2555);
	$rational_factorials{9957}=5.1018707467784013969803742245717*(10**2554);
	$rational_factorials{9956}=2.5579790075663199880163001891597*(10**2554);
	$rational_factorials{9955}=1.2825339207894033473003733906160*(10**2554);
	$rational_factorials{9954}=6.4305053645241444149624877641175*(10**2553);
	$rational_factorials{9953}=3.2242277409826066967432115700436*(10**2553);
	$rational_factorials{9952}=1.6166301607479522116991147813798*(10**2553);
	$rational_factorials{9951}=8.1058769247156077242250107297621*(10**2552);
	$rational_factorials{9950}=4.0643742937291181007170762050500*(10**2552);
	$rational_factorials{9949}=2.0379416677401478790661217961626*(10**2552);
	$rational_factorials{9948}=1.0218665076487721781512729070618*(10**2552);
	$rational_factorials{9947}=5.1239035319658545716384194281125*(10**2551);
	$rational_factorials{9946}=2.5692838565350743150023103547205*(10**2551);
	$rational_factorials{9945}=1.2883314121440515794077080769624*(10**2551);
	$rational_factorials{9944}=6.4602223875066751205168653447032*(10**2550);
	$rational_factorials{9943}=3.2394531708857698148731152115378*(10**2550);
	$rational_factorials{9942}=1.6244274123271223992153484539589*(10**2550);
	$rational_factorials{9941}=8.1457913020958775240930667568707*(10**2549);
	$rational_factorials{9940}=4.0847982851548925635347499548241*(10**2549);
	$rational_factorials{9939}=2.0483884488291766801348093237135*(10**2549);
	$rational_factorials{9938}=1.0272079891925735606667399548269*(10**2549);
	$rational_factorials{9937}=5.1512049180314211034868999981025*(10**2548);
	$rational_factorials{9936}=2.5832333164438712195880860192243*(10**2548);
	$rational_factorials{9935}=1.2954564224676235087055888154473*(10**2548);
	$rational_factorials{9934}=6.4966033663582814968995025590338*(10**2547);
	$rational_factorials{9933}=3.2580239071565622195244043161398*(10**2547);
	$rational_factorials{9932}=1.6339040558510585387400406899606*(10**2547);
	$rational_factorials{9931}=8.1941367086770722503702512391819*(10**2546);
	$rational_factorials{9930}=4.1094550152463707882643359706480*(10**2546);
	$rational_factorials{9929}=2.0609603067000469666312600097731*(10**2546);
	$rational_factorials{9928}=1.0336164109404040658751659839273*(10**2546);
	$rational_factorials{9927}=5.1838632565476714335180638000428*(10**2545);
	$rational_factorials{9926}=2.5998725004467302934662701481726*(10**2545);
	$rational_factorials{9925}=1.3039319803398324194318961403597*(10**2545);
	$rational_factorials{9924}=6.5397658207753991311651928317231*(10**2544);
	$rational_factorials{9923}=3.2799999065303153322504825492196*(10**2544);
	$rational_factorials{9922}=1.6450906724235386012283937675802*(10**2544);
	$rational_factorials{9921}=8.2510690853660983288392420090443*(10**2543);
	$rational_factorials{9920}=4.1384239831282686689469647237140*(10**2543);
	$rational_factorials{9919}=2.0756977608017393157732500853793*(10**2543);
	$rational_factorials{9918}=1.0411124203670468028557272199106*(10**2543);
	$rational_factorials{9917}=5.2219837378338586013076093482852*(10**2542);
	$rational_factorials{9916}=2.6192549873531435557790350072261*(10**2542);
	$rational_factorials{9915}=1.3137853706194785082437240708913*(10**2542);
	$rational_factorials{9914}=6.5898486706725102087517057957710*(10**2541);
	$rational_factorials{9913}=3.3054518860529228381038824440387*(10**2541);
	$rational_factorials{9912}=1.6580232538032035892243436480348*(10**2541);
	$rational_factorials{9911}=8.3167715808548516569289809586174*(10**2540);
	$rational_factorials{9910}=4.1717983700889805130513757295504*(10**2540);
	$rational_factorials{9909}=2.0926482113133776749402662419390*(10**2540);
	$rational_factorials{9908}=1.0497201253952881658154136115251*(10**2540);
	$rational_factorials{9907}=5.2656889561700701838334267906476*(10**2539);
	$rational_factorials{9906}=2.6414431094727143563725645494414*(10**2539);
	$rational_factorials{9905}=1.3250482810080469069528230669605*(10**2539);
	$rational_factorials{9904}=6.6470129823204662182284706433034*(10**2538);
	$rational_factorials{9903}=3.3344617028678733361281977645906*(10**2538);
	$rational_factorials{9902}=1.6727433956852336453030101372426*(10**2538);
	$rational_factorials{9901}=8.3914555351173964856512773268261*(10**2537);
	$rational_factorials{9900}=4.2096855399485171675594104233606*(10**2537);
	$rational_factorials{9899}=2.1118661936758277070746455161358*(10**2537);
	$rational_factorials{9898}=1.0594672238547518831403044121166*(10**2537);
	$rational_factorials{9897}=5.3151195681539014674810000914985*(10**2536);
	$rational_factorials{9896}=2.6665082873740302406345291231995*(10**2536);
	$rational_factorials{9895}=1.3377569722443684068175901736098*(10**2536);
	$rational_factorials{9894}=6.7114428335222801072581488724792*(10**2535);
	$rational_factorials{9893}=3.3671227939693762861034007518839*(10**2535);
	$rational_factorials{9892}=1.6892985211929243034770855758863*(10**2535);
	$rational_factorials{9891}=8.4753616151069553435524465476479*(10**2534);
	$rational_factorials{9890}=4.2522076161096133005650610336976*(10**2534);
	$rational_factorials{9889}=2.1334136717606098667286044207858*(10**2534);
	$rational_factorials{9888}=1.0703851524093270187313643282649*(10**2534);
	$rational_factorials{9887}=5.3704350491602520637374963034238*(10**2533);
	$rational_factorials{9886}=2.69453141408046709845849749717*(10**2533);
	$rational_factorials{9885}=1.3519524732131060200278829445273*(10**2533);
	$rational_factorials{9884}=6.7833463043483728595695864892654*(10**2532);
	$rational_factorials{9883}=3.4035406792372144810506426280035*(10**2532);
	$rational_factorials{9882}=1.7077421362645817867742474483282*(10**2532);
	$rational_factorials{9881}=8.5687611112192451153093181151025*(10**2531);
	$rational_factorials{9880}=4.2995021396457161785288786993909*(10**2531);
	$rational_factorials{9879}=2.1573603718885730273319895042833*(10**2531);
	$rational_factorials{9878}=1.0825092560773938296231435358666*(10**2531);
	$rational_factorials{9877}=5.4318145536161141536740126463273*(10**2530);
	$rational_factorials{9876}=2.7256032916047613781696312939207*(10**2530);
	$rational_factorials{9875}=1.367680802441179585258354015708*(10**2530);
	$rational_factorials{9874}=6.8629566009190336499085253837165*(10**2529);
	$rational_factorials{9873}=3.4438335315564246494491982474993*(10**2529);
	$rational_factorials{9872}=1.7281341188672149228640431575877*(10**2529);
	$rational_factorials{9871}=8.6719574043307814141375550198386*(10**2528);
	$rational_factorials{9870}=4.3517228134065953223976505054564*(10**2528);
	$rational_factorials{9869}=2.1837841602273236434173393099335*(10**2528);
	$rational_factorials{9868}=1.0958789796288659947592058472025*(10**2528);
	$rational_factorials{9867}=5.4994578856091061594350639326995*(10**2527);
	$rational_factorials{9866}=2.7598251231315931330190677338201*(10**2527);
	$rational_factorials{9865}=1.3849932176619540103882065981853*(10**2527);
	$rational_factorials{9864}=6.9505333207606174295204834755079*(10**2526);
	$rational_factorials{9863}=3.4881328183494628273566274156784*(10**2526);
	$rational_factorials{9862}=1.7505410442334024745381312374268*(10**2526);
	$rational_factorials{9861}=8.7852876145585871888740300069279*(10**2525);
	$rational_factorials{9860}=4.4090403377979689183360187491959*(10**2525);
	$rational_factorials{9859}=2.2127714664376569494552024621882*(10**2525);
	$rational_factorials{9858}=1.1105380823154296663550930758031*(10**2525);
	$rational_factorials{9857}=5.5735865872191204615739981075297*(10**2524);
	$rational_factorials{9856}=2.7973090645971955534350980476587*(10**2524);
	$rational_factorials{9855}=1.4039464953491677753555059282162*(10**2524);
	$rational_factorials{9854}=7.0463638693842431361724285031508*(10**2523);
	$rational_factorials{9853}=3.5365840194154545547567955142232*(10**2523);
	$rational_factorials{9852}=1.77503654860413960103237805458*(10**2523);
	$rational_factorials{9851}=8.9091244443348414855227968836101*(10**2522);
	$rational_factorials{9850}=4.4716433446226865297525545123691*(10**2522);
	$rational_factorials{9849}=2.2444177568086590419466502304374*(10**2522);
	$rational_factorials{9848}=1.126534877577023398615432213231*(10**2522);
	$rational_factorials{9847}=5.6544451529056715649528234833414*(10**2521);
	$rational_factorials{9846}=2.8381788398916350988586627918615*(10**2521);
	$rational_factorials{9845}=1.4246032423634376208579461473528*(10**2521);
	$rational_factorials{9844}=7.1507650389529562981250542958705*(10**2520);
	$rational_factorials{9843}=3.5893474265862727643933781733718*(10**2520);
	$rational_factorials{9842}=1.801701734271355664872490920199*(10**2520);
	$rational_factorials{9841}=9.0438782299612643239496466182216*(10**2519);
	$rational_factorials{9840}=4.5397394361651639895965020430143*(10**2519);
	$rational_factorials{9839}=2.278828060522549540000660199449*(10**2519);
	$rational_factorials{9838}=1.1439224995704949214210318980818*(10**2519);
	$rational_factorials{9837}=5.7423023793091008073045836126144*(10**2518);
	$rational_factorials{9836}=2.8825704244278235820217984885857*(10**2518);
	$rational_factorials{9835}=1.4470322421162393304803922268693*(10**2518);
	$rational_factorials{9834}=7.2640847612281148904155366678896*(10**2517);
	$rational_factorials{9833}=3.6465990313789218372380150090133*(10**2517);
	$rational_factorials{9832}=1.8306256190523833213498180453149*(10**2517);
	$rational_factorials{9831}=9.1899992175198296148253700012413*(10**2516);
	$rational_factorials{9830}=4.6135563375662235666631118323316*(10**2516);
	$rational_factorials{9829}=2.3161175531279088728536032111485*(10**2516);
	$rational_factorials{9828}=1.1627591985876142726377636695282*(10**2516);
	$rational_factorials{9827}=5.8374528609424629534457493266387*(10**2515);
	$rational_factorials{9826}=2.9306328023869698881880830506158*(10**2515);
	$rational_factorials{9825}=1.4713088379422870670873332250832*(10**2515);
	$rational_factorials{9824}=7.3867040484320875436399600039552*(10**2514);
	$rational_factorials{9823}=3.7085315075550918714919302440896*(10**2514);
	$rational_factorials{9822}=1.8619056336985184309904577352674*(10**2514);
	$rational_factorials{9821}=9.3479800808868168190676126551127*(10**2513);
	$rational_factorials{9820}=4.6933431714814074940621687002356*(10**2513);
	$rational_factorials{9819}=2.3564122017783181125786989634231*(10**2513);
	$rational_factorials{9818}=1.1831086676715651939741185078634*(10**2513);
	$rational_factorials{9817}=5.9402186434745730675137369763291*(10**2512);
	$rational_factorials{9816}=2.9825288035690717364014686043312*(10**2512);
	$rational_factorials{9815}=1.4975153566842616458904154962679*(10**2512);
	$rational_factorials{9814}=7.5190391372476461152686889291075*(10**2511);
	$rational_factorials{9813}=3.7753552962995946976401610954796*(10**2511);
	$rational_factorials{9812}=1.8956481711448976084203397834122*(10**2511);
	$rational_factorials{9811}=9.5183587016462853264103580644667*(10**2510);
	$rational_factorials{9810}=4.7793718650523497902873408352705*(10**2510);
	$rational_factorials{9809}=2.3998494773177697449625205860302*(10**2510);
	$rational_factorials{9808}=1.2050404030062794805195747686529*(10**2510);
	$rational_factorials{9807}=6.050951047646504092404743787643*(10**2509);
	$rational_factorials{9806}=3.0384360264558595521612353344857*(10**2509);
	$rational_factorials{9805}=1.525741575837250785420698416982*(10**2509);
	$rational_factorials{9804}=7.6615438529118057013131128277028*(10**2508);
	$rational_factorials{9803}=3.8472998026083712398248864725156*(10**2508);
	$rational_factorials{9802}=1.9319691919536257729518342676439*(10**2508);
	$rational_factorials{9801}=9.7017212329490218391706839919139*(10**2507);
	$rational_factorials{9800}=4.8719387003591740981522332673501*(10**2507);
	$rational_factorials{9799}=2.4465791388701903812442864573659*(10**2507);
	$rational_factorials{9798}=1.22863010094441219465698895662*(10**2507);
	$rational_factorials{9797}=6.1700326783384359053785497987591*(10**2506);
	$rational_factorials{9796}=3.0985478548397507160526568779173*(10**2506);
	$rational_factorials{9795}=1.5560852379778182411225889005426*(10**2506);
	$rational_factorials{9794}=7.814712212272343636590282361998*(10**2505);
	$rational_factorials{9793}=3.9246147124435083544066984316185*(10**2505);
	$rational_factorials{9792}=1.9709948907912933819137260433012*(10**2505);
	$rational_factorials{9791}=9.8987054718386101817882705763839*(10**2504);
	$rational_factorials{9790}=4.9713660207746674470941155789287*(10**2504);
	$rational_factorials{9789}=2.4967640972244008380898933129563*(10**2504);
	$rational_factorials{9788}=1.253960094860596238678290423168*(10**2504);
	$rational_factorials{9787}=6.29787963492746341265545554635*(10**2503);
	$rational_factorials{9786}=3.1630745761941105717156562657384*(10**2503);
	$rational_factorials{9785}=1.5886526166184974386141795819731*(10**2503);
	$rational_factorials{9784}=7.9790812867800118813460101715315*(10**2502);
	$rational_factorials{9783}=4.0075714412779621713537204448264*(10**2502);
	$rational_factorials{9782}=2.0128624293211737968890176095805*(10**2502);
	$rational_factorials{9781}=1.0110004567295077297301879865574*(10**2502);
	$rational_factorials{9780}=5.0780041070221322237937850653*(10**2501);
	$rational_factorials{9779}=2.5505813640049043192255524700749*(10**2501);
	$rational_factorials{9778}=1.2811198353704497738846448949408*(10**2501);
	$rational_factorials{9777}=6.4349439408679507639271028367732*(10**2500);
	$rational_factorials{9776}=3.2322446108666570322048398382775*(10**2500);
	$rational_factorials{9775}=1.6235591380873760231110675339531*(10**2500);
	$rational_factorials{9774}=8.1552343487121952998221690224157*(10**2499);
	$rational_factorials{9773}=4.0964647258284393042560773227297*(10**2499);
	$rational_factorials{9772}=2.0577207414855589827121423119817*(10**2499);
	$rational_factorials{9771}=1.0336371094259357220429281122149*(10**2499);
	$rational_factorials{9770}=5.1922332382639388791347495555215*(10**2498);
	$rational_factorials{9769}=2.6082230943909441857301896615962*(10**2498);
	$rational_factorials{9768}=1.3102064178466452995343064992235*(10**2498);
	$rational_factorials{9767}=6.5817162124045727359385321026626*(10**2497);
	$rational_factorials{9766}=3.3063058621794773242684531897274*(10**2497);
	$rational_factorials{9765}=1.6609300645395151131571023365249*(10**2497);
	$rational_factorials{9764}=8.3438043264908894002682310440103*(10**2496);
	$rational_factorials{9763}=4.1916143720745311616249640056581*(10**2496);
	$rational_factorials{9762}=2.105731417811664943422167736371*(10**2496);
	$rational_factorials{9761}=1.0578621527232992754507502939463*(10**2496);
	$rational_factorials{9760}=5.3144659552343284330959565563168*(10**2495);
	$rational_factorials{9759}=2.6698977320001475951788204131397*(10**2495);
	$rational_factorials{9758}=1.3413251615956647210629673415474*(10**2495);
	$rational_factorials{9757}=6.7387285885170192852856886481649*(10**2494);
	$rational_factorials{9756}=3.3855271986273574895232983716234*(10**2494);
	$rational_factorials{9755}=1.7009012437680646320093213891704*(10**2494);
	$rational_factorials{9754}=8.5454775977989444902378441663358*(10**2493);
	$rational_factorials{9753}=4.2933671741007181825514329669754*(10**2493);
	$rational_factorials{9752}=2.1570696761029143038538903261329*(10**2493);
	$rational_factorials{9751}=1.0837641150735572947963838684011*(10**2493);
	$rational_factorials{9750}=5.4451495442974676568606112257344*(10**2492);
	$rational_factorials{9749}=2.7358312654986654320922434810326*(10**2492);
	$rational_factorials{9748}=1.3745902455376764921735676793886*(10**2492);
	$rational_factorials{9747}=6.9065579466198824282932137420978*(10**2491);
	$rational_factorials{9746}=3.4702000805938473652350331812458*(10**2491);
	$rational_factorials{9745}=1.7436199321046280184616313574273*(10**2491);
	$rational_factorials{9744}=8.7609981523466726371107690858477*(10**2490);
	$rational_factorials{9743}=4.4020990198920518635819060463195*(10**2490);
	$rational_factorials{9742}=2.2119254266846947332381976272897*(10**2490);
	$rational_factorials{9741}=1.111438944799053732741650977747*(10**2490);
	$rational_factorials{9740}=5.5847687633820181096006268981891*(10**2489);
	$rational_factorials{9739}=2.8062686075481233276153897641118*(10**2489);
	$rational_factorials{9738}=1.4101254057629016128165446033942*(10**2489);
	$rational_factorials{9737}=7.0858294312300014653669988120425*(10**2488);
	$rational_factorials{9736}=3.5606403453661475120408713125855*(10**2488);
	$rational_factorials{9735}=1.7892456973880225946245575756053*(10**2488);
	$rational_factorials{9734}=8.9911721596332847260989009501721*(10**2487);
	$rational_factorials{9733}=4.5182172019830153582899579660469*(10**2487);
	$rational_factorials{9732}=2.2705044412694464516918472873021*(10**2487);
	$rational_factorials{9731}=1.140990601374657358322195850269*(10**2487);
	$rational_factorials{9730}=5.733848833041086354826105644958*(10**2486);
	$rational_factorials{9729}=2.8814751078633569438498714078569*(10**2486);
	$rational_factorials{9728}=1.4480647009271940981890989971187*(10**2486);
	$rational_factorials{9727}=7.2772203257985020698028127883768*(10**2485);
	$rational_factorials{9726}=3.6571901657417291619154388995332*(10**2485);
	$rational_factorials{9725}=1.8379514097462995322286158968724*(10**2485);
	$rational_factorials{9724}=9.2368729809259140395509563901501*(10**2484);
	$rational_factorials{9723}=4.6421629528234001420835898140829*(10**2484);
	$rational_factorials{9722}=2.3330296355008697612945409857194*(10**2484);
	$rational_factorials{9721}=1.1725317042181249186334352587288*(10**2484);
	$rational_factorials{9720}=5.8929587184389376719692760996485*(10**2483);
	$rational_factorials{9719}=2.9617382134477921100317313268135*(10**2483);
	$rational_factorials{9718}=1.4885533521044347226450441993407*(10**2483);
	$rational_factorials{9717}=7.4814643012218588154650074929339*(10**2482);
	$rational_factorials{9716}=3.7602201991998037856420305362258*(10**2482);
	$rational_factorials{9715}=1.8899243287879686706720986086091*(10**2482);
	$rational_factorials{9714}=9.4990466689900391192420366003189*(10**2481);
	$rational_factorials{9713}=4.7744142269087731585761491454108*(10**2481);
	$rational_factorials{9712}=2.3997424763432110278693077409169*(10**2481);
	$rational_factorials{9711}=1.2061842446436836936873112423915*(10**2481);
	$rational_factorials{9710}=6.0627147309042568641659219132187*(10**2480);
	$rational_factorials{9709}=3.0473692905111555818826333231953*(10**2480);
	$rational_factorials{9708}=1.5317486644416903916907225759835*(10**2480);
	$rational_factorials{9707}=7.6993560782359357985643794308263*(10**2479);
	$rational_factorials{9706}=3.8701319464798309856340371924925*(10**2479);
	$rational_factorials{9705}=1.9453672967452070722306727829224*(10**2479);
	$rational_factorials{9704}=9.7787180039016256117377358455002*(10**2478);
	$rational_factorials{9703}=4.9154887541529632024875415890156*(10**2478);
	$rational_factorials{9702}=2.4709045267125319479708687612406*(10**2478);
	$rational_factorials{9701}=1.2420803672574232248865320177031*(10**2478);
	$rational_factorials{9700}=6.2437844808488742164427620115537*(10**2477);
	$rational_factorials{9699}=3.1387056241746375341256909292361*(10**2477);
	$rational_factorials{9698}=1.5778210387738879189232824227271*(10**2477);
	$rational_factorials{9697}=7.9317565450045696904959095815662*(10**2476);
	$rational_factorials{9696}=3.9873603404902441640573224732048*(10**2476);
	$rational_factorials{9695}=2.0045000481661072356833310488639*(10**2476);
	$rational_factorials{9694}=1.0076997118612557308056199346146*(10**2476);
	$rational_factorials{9693}=5.0659473916860385473436479326142*(10**2475);
	$rational_factorials{9692}=2.5467991411178436899308068039998*(10**2475);
	$rational_factorials{9691}=1.2803632277676767600108566309691*(10**2475);
	$rational_factorials{9690}=6.436891217369973419013156712942*(10**2474);
	$rational_factorials{9689}=3.2361126138515697846434590465368*(10**2474);
	$rational_factorials{9688}=1.6269550822580819951776473734039*(10**2474);
	$rational_factorials{9687}=8.1795983757910381463296994756793*(10**2473);
	$rational_factorials{9686}=4.1123765887894432385079645969521*(10**2473);
	$rational_factorials{9685}=2.0675606479279084432009603392098*(10**2473);
	$rational_factorials{9684}=1.0395086773893704670988445787236*(10**2473);
	$rational_factorials{9683}=5.2263978042773532934526441066896*(10**2472);
	$rational_factorials{9682}=2.6277333276081754951824255096985*(10**2472);
	$rational_factorials{9681}=1.3211879349578751006200150974813*(10**2472);
	$rational_factorials{9680}=6.6428185937770623519227623456574*(10**2471);
	$rational_factorials{9679}=3.3399861841795539112844040112879*(10**2471);
	$rational_factorials{9678}=1.6793508280946345945268862235796*(10**2471);
	$rational_factorials{9677}=8.443892201704385409651800842035*(10**2470);
	$rational_factorials{9676}=4.2456912954671105084740497593972*(10**2470);
	$rational_factorials{9675}=2.1348070706534934880753333394009*(10**2470);
	$rational_factorials{9674}=1.073429034891956285727844463779*(10**2470);
	$rational_factorials{9673}=5.3974985069475919585383084856858*(10**2469);
	$rational_factorials{9672}=2.7140397930264155083478883595316*(10**2469);
	$rational_factorials{9671}=1.3647225854331939888648022905498*(10**2469);
	$rational_factorials{9670}=6.8624159026622544957879776298113*(10**2468);
	$rational_factorials{9669}=3.4507554335980513599384275351667*(10**2468);
	$rational_factorials{9668}=1.7352250755265908188953153787762*(10**2468);
	$rational_factorials{9667}=8.7257333902081072746220944941975*(10**2467);
	$rational_factorials{9666}=4.38785789114004806580616965626*(10**2467);
	$rational_factorials{9665}=2.2065189360759622615765719270294*(10**2467);
	$rational_factorials{9664}=1.1096020621169694911389750504228*(10**2467);
	$rational_factorials{9663}=5.5799633070894158570643114707803*(10**2466);
	$rational_factorials{9662}=2.8060791904739614437012906943048*(10**2466);
	$rational_factorials{9661}=1.4111494007167759165182528079307*(10**2466);
	$rational_factorials{9660}=7.0966038290199115778572674558545*(10**2465);
	$rational_factorials{9659}=3.5688855451422601716190169977937*(10**2465);
	$rational_factorials{9658}=1.7948128625637058532222955924454*(10**2465);
	$rational_factorials{9657}=9.0263094964395440929162040904081*(10**2464);
	$rational_factorials{9656}=4.5394764030002566374986236874198*(10**2464);
	$rational_factorials{9655}=2.2829994165297074615380982173093*(10**2464);
	$rational_factorials{9654}=1.1481809417601091588772506730368*(10**2464);
	$rational_factorials{9653}=5.7745661876119381735116542179244*(10**2463);
	$rational_factorials{9652}=2.9042425900165198133940081704666*(10**2463);
	$rational_factorials{9651}=1.4606659773489037537710928557403*(10**2463);
	$rational_factorials{9650}=7.3463807753829312400178752130999*(10**2462);
	$rational_factorials{9649}=3.6948809867918626893249994800639*(10**2462);
	$rational_factorials{9648}=1.8583690852802918339431513692745*(10**2462);
	$rational_factorials{9647}=9.3469084564974050874145222019345*(10**2461);
	$rational_factorials{9646}=4.7011976004559410081800162462923*(10**2461);
	$rational_factorials{9645}=2.3645773345724572361865336274565*(10**2461);
	$rational_factorials{9644}=1.189331822830028132253211801364*(10**2461);
	$rational_factorials{9643}=5.9821466773147603579318908297155*(10**2460);
	$rational_factorials{9642}=3.0089541960386653682076338276695*(10**2460);
	$rational_factorials{9641}=1.5134866618473772187038574818571*(10**2460);
	$rational_factorials{9640}=7.6128298190496696787750002208289*(10**2459);
	$rational_factorials{9639}=3.8292890318083352568400865168037*(10**2459);
	$rational_factorials{9638}=1.9261702791047800932246593794305*(10**2459);
	$rational_factorials{9637}=9.6889276008058516506836552316103*(10**2458);
	$rational_factorials{9636}=4.8737275559360781755961188537137*(10**2458);
	$rational_factorials{9635}=2.4516094707853366886330053161809*(10**2458);
	$rational_factorials{9634}=1.23323498841769818773663604455*(10**2458);
	$rational_factorials{9633}=6.2036157599447893372725197860785*(10**2457);
	$rational_factorials{9632}=3.1206743373145253766932522585247*(10**2457);
	$rational_factorials{9631}=1.5698440637354809861050279865752*(10**2457);
	$rational_factorials{9630}=7.8971263683087859738329877809429*(10**2456);
	$rational_factorials{9629}=3.9727036329581235157589859080856*(10**2456);
	$rational_factorials{9628}=1.9985165792745176314843944588405*(10**2456);
	$rational_factorials{9627}=1.0053883574562469285756620557861*(10**2456);
	$rational_factorials{9626}=5.0578326649398901780781640241944*(10**2455);
	$rational_factorials{9625}=2.5444831040844179435734357199595*(10**2455);
	$rational_factorials{9624}=1.2800861411850718162099190829873*(10**2455);
	$rational_factorials{9623}=6.4399623792637696847010482571146*(10**2454);
	$rational_factorials{9622}=3.2399027588398311635104363149135*(10**2454);
	$rational_factorials{9621}=1.629990721353422267786344083247*(10**2454);
	$rational_factorials{9620}=8.2005465922209615512284400632844*(10**2453);
	$rational_factorials{9619}=4.125769688397677345268445225969*(10**2453);
	$rational_factorials{9618}=2.0757338795954690813090927075618*(10**2453);
	$rational_factorials{9617}=1.0443423262244177091260642524006*(10**2453);
	$rational_factorials{9616}=5.2543451744648765614774195140187*(10**2452);
	$rational_factorials{9615}=2.6436188094383563050113617869709*(10**2452);
	$rational_factorials{9614}=1.3300978191864835995531162541431*(10**2452);
	$rational_factorials{9613}=6.692260604035924020265040275501*(10**2451);
	$rational_factorials{9612}=3.3671822478069332399817463260377*(10**2451);
	$rational_factorials{9611}=1.6942009368604326658209584068673*(10**2451);
	$rational_factorials{9610}=8.5244767070903966228985863443705*(10**2450);
	$rational_factorials{9609}=4.2891877413428395314153708555661*(10**2450);
	$rational_factorials{9608}=2.1581762108499366617894496855498*(10**2450);
	$rational_factorials{9607}=1.0859335824315459177769202998863*(10**2450);
	$rational_factorials{9606}=5.4641692746098965905547207924488*(10**2449);
	$rational_factorials{9605}=2.7494735407575208580461381039739*(10**2449);
	$rational_factorials{9604}=1.3835009560916201368349451364084*(10**2449);
	$rational_factorials{9603}=6.961677524223368376432997269844*(10**2448);
	$rational_factorials{9602}=3.503102629844915980005978283435*(10**2448);
	$rational_factorials{9601}=1.7627727987310713409852860335733*(10**2448);
	$rational_factorials{9600}=8.8704232123729413349621085789495*(10**2447);
	$rational_factorials{9599}=4.463719160519137820184588256391*(10**2447);
	$rational_factorials{9598}=2.2462283626664619710547977576497*(10**2447);
	$rational_factorials{9597}=1.1303565966811136856218593732552*(10**2447);
	$rational_factorials{9596}=5.6882878145012456699507815869756*(10**2446);
	$rational_factorials{9595}=2.8625440299401570619949381613471*(10**2446);
	$rational_factorials{9594}=1.4405466015114745281496721536948*(10**2446);
	$rational_factorials{9593}=7.2494819579541480541841062895387*(10**2445);
	$rational_factorials{9592}=3.6483051758434867527660677811237*(10**2445);
	$rational_factorials{9591}=1.8360304121769308832260035762663*(10**2445);
	$rational_factorials{9590}=9.2400241795551472239188631030724*(10**2444);
	$rational_factorials{9589}=4.6501918538588788625737975376508*(10**2444);
	$rational_factorials{9588}=2.340308775439114368675555071525*(10**2444);
	$rational_factorials{9587}=1.1778228578525723513825772358604*(10**2444);
	$rational_factorials{9586}=5.9277697108183052000320775187324*(10**2443);
	$rational_factorials{9585}=2.983370536675515437201603086344*(10**2443);
	$rational_factorials{9584}=1.5015078189613034481443320342868*(10**2443);
	$rational_factorials{9583}=7.5570540581196164434317797243184*(10**2442);
	$rational_factorials{9582}=3.8034874643906242209821390545493*(10**2442);
	$rational_factorials{9581}=1.9143263603137638236117230489691*(10**2442);
	$rational_factorials{9580}=9.6350617096508313075274902013268*(10**2441);
	$rational_factorials{9579}=4.8495065740524338956865132314639*(10**2441);
	$rational_factorials{9578}=2.4408727319974075601538955689664*(10**2441);
	$rational_factorials{9577}=1.2285624886331202163164464752898*(10**2441);
	$rational_factorials{9576}=6.1837781252016536616232813673403*(10**2440);
	$rational_factorials{9575}=3.1125409876635528817961430217465*(10**2440);
	$rational_factorials{9574}=1.5666817810531129467282262461256*(10**2440);
	$rational_factorials{9573}=7.8858959178958744061690282002697*(10**2439);
	$rational_factorials{9572}=3.9694087501467587361533490446142*(10**2439);
	$rational_factorials{9571}=1.9980444215778768642226521751061*(10**2439);
	$rational_factorials{9570}=1.005747568857080512268005240222*(10**2439);
	$rational_factorials{9569}=5.0626438814619833966870375106629*(10**2438);
	$rational_factorials{9568}=2.5484158822274040093483979630052*(10**2438);
	$rational_factorials{9567}=1.2828260296889633667290868490026*(10**2438);
	$rational_factorials{9566}=6.4575794958246174411270690970554*(10**2437);
	$rational_factorials{9565}=3.2506955484736844718497577250616*(10**2437);
	$rational_factorials{9564}=1.6363920838240160295887050826464*(10**2437);
	$rational_factorials{9563}=8.2376432862173554853954123057241*(10**2436);
	$rational_factorials{9562}=4.1468958944282895279495915635334*(10**2436);
	$rational_factorials{9561}=2.0876025719129420794302081027124*(10**2436);
	$rational_factorials{9560}=1.0509378984922471392560138351327*(10**2436);
	$rational_factorials{9559}=5.2906718376653604312749895607303*(10**2435);
	$rational_factorials{9558}=2.6634781377794774345196467004653*(10**2435);
	$rational_factorials{9557}=1.3408864112981743145490611989157*(10**2435);
	$rational_factorials{9556}=6.7505535185287658803335449477895*(10**2434);
	$rational_factorials{9555}=3.3985316763969518785674414271423*(10**2434);
	$rational_factorials{9554}=1.7109913047093434019120713954897*(10**2434);
	$rational_factorials{9553}=8.614078517429002912679506750731*(10**2433);
	$rational_factorials{9552}=4.3368499209666278267617564981525*(10**2433);
	$rational_factorials{9551}=2.1834563036428638002616965826927*(10**2433);
	$rational_factorials{9550}=1.0993074252010953339498052668752*(10**2433);
	$rational_factorials{9549}=5.5347545116281623927973528200966*(10**2432);
	$rational_factorials{9548}=2.7866479784259023169278580251782*(10**2432);
	$rational_factorials{9547}=1.4030411335127909538025125027892*(10**2432);
	$rational_factorials{9546}=7.0642041843122288408680880575445*(10**2431);
	$rational_factorials{9545}=3.5568097084217183449162129012478*(10**2431);
	$rational_factorials{9544}=1.7908638315986428740967881468387*(10**2431);
	$rational_factorials{9543}=9.0171448941997308831566070875442*(10**2430);
	$rational_factorials{9542}=4.5402532673436220966936311747828*(10**2430);
	$rational_factorials{9541}=2.2861022967677351065455937416947*(10**2430);
	$rational_factorials{9540}=1.151107251519471553874141640707*(10**2430);
	$rational_factorials{9539}=5.796161390332141996855537564244*(10**2429);
	$rational_factorials{9538}=2.9185672166169902774694784511712*(10**2429);
	$rational_factorials{9537}=1.4696146784464134846574971224356*(10**2429);
	$rational_factorials{9536}=7.4001719927846520436497884533254*(10**2428);
	$rational_factorials{9535}=3.7263590449677510161510873768966*(10**2428);
	$rational_factorials{9534}=1.8764289937119057775532147389341*(10**2428);
	$rational_factorials{9533}=9.4489624795134977293897171618404*(10**2427);
	$rational_factorials{9532}=4.7581778110916182107457882779111*(10**2427);
	$rational_factorials{9531}=2.3960824827248035913904137319932*(10**2427);
	$rational_factorials{9530}=1.2066113747583559264928109441374*(10**2427);
	$rational_factorials{9529}=6.0762777967629122516569216524206*(10**2426);
	$rational_factorials{9528}=3.0599362724019608696471780783929*(10**2426);
	$rational_factorials{9527}=1.5409611811328651406705432761199*(10**2426);
	$rational_factorials{9526}=7.7602474756550461867132848713564*(10**2425);
	$rational_factorials{9525}=3.9080849973442590625601335887746*(10**2425);
	$rational_factorials{9524}=1.9681445287517367081531516036649*(10**2425);
	$rational_factorials{9523}=9.9118456724152918592150604865628*(10**2424);
	$rational_factorials{9522}=4.9917937590134475563845869470322*(10**2424);
	$rational_factorials{9521}=2.5139885455091843367856612443534*(10**2424);
	$rational_factorials{9520}=1.2661189661682643509893084408577*(10**2424);
	$rational_factorials{9519}=6.3766164306463556004375292815831*(10**2423);
	$rational_factorials{9518}=3.2115200172144845399319669168691*(10**2423);
	$rational_factorials{9517}=1.6174673886143225996331933201637*(10**2423);
	$rational_factorials{9516}=8.1463861806162567569948403016548*(10**2422);
	$rational_factorials{9515}=4.1029763751645764436326861824405*(10**2422);
	$rational_factorials{9514}=2.0665104249808239270822675384974*(10**2422);
	$rational_factorials{9513}=1.0408322663462450760490455199583*(10**2422);
	$rational_factorials{9512}=5.2423794990689430333801585245035*(10**2421);
	$rational_factorials{9511}=2.6404669105232479117589131859609*(10**2421);
	$rational_factorials{9510}=1.329956897235571797257676933674*(10**2421);
	$rational_factorials{9509}=6.6988301614101855241491010416884*(10**2420);
	$rational_factorials{9508}=3.374154252169031876373152885973*(10**2420);
	$rational_factorials{9507}=1.6995559405425266361597071768033*(10**2420);
	$rational_factorials{9506}=8.5607252843802614092001264204023*(10**2419);
	$rational_factorials{9505}=4.3121138992796389318262597818608*(10**2419);
	$rational_factorials{9504}=2.1720731816069202512952149868587*(10**2419);
	$rational_factorials{9503}=1.0941157009841743677589041521689*(10**2419);
	$rational_factorials{9502}=5.5113325263550704724349858331618*(10**2418);
	$rational_factorials{9501}=2.7762242777029207357364243359909*(10**2418);
	$rational_factorials{9500}=1.3984825417829356438040766915605*(10**2418);
	$rational_factorials{9499}=7.044726218750852375800926534534*(10**2417);
	$rational_factorials{9498}=3.5487528945824904042628869225631*(10**2417);
	$rational_factorials{9497}=1.7876890086699554393180889626625*(10**2417);
	$rational_factorials{9496}=9.0056020243848741944036675998341*(10**2416);
	$rational_factorials{9495}=4.5366795363278684185441975611371*(10**2416);
	$rational_factorials{9494}=2.2854305362025676044772884962739*(10**2416);
	$rational_factorials{9493}=1.1513371577230078583172726004093*(10**2416);
	$rational_factorials{9492}=5.8001815684646079482582465093262*(10**2415);
	$rational_factorials{9491}=2.9220337624491324447283699989379*(10**2415);
	$rational_factorials{9490}=1.47208688608730067768850178059*(10**2415);
	$rational_factorials{9489}=7.4162819441529133338255885193536*(10**2414);
	$rational_factorials{9488}=3.7363159555511585641849725442863*(10**2414);
	$rational_factorials{9487}=1.8823723372327634403686311073629*(10**2414);
	$rational_factorials{9486}=9.4835741621576181491192792753097*(10**2413);
	$rational_factorials{9485}=4.7779668629045480974662428237357*(10**2413);
	$rational_factorials{9484}=2.4072367139272883973849678705223*(10**2413);
	$rational_factorials{9483}=1.2128275126124595579029522810589*(10**2413);
	$rational_factorials{9482}=6.1106000510583733125350258210348*(10**2412);
	$rational_factorials{9481}=3.0787417157824596404260562627098*(10**2412);
	$rational_factorials{9480}=1.5511979832321398078909397055743*(10**2412);
	$rational_factorials{9479}=7.8156622870196156958853288221663*(10**2411);
	$rational_factorials{9478}=3.9379384017191806114934364927132*(10**2411);
	$rational_factorials{9477}=1.9841597314564809111084970036501*(10**2411);
	$rational_factorials{9476}=9.9974427178553849347662653123653*(10**2410);
	$rational_factorials{9475}=5.0373925808166031602174410371489*(10**2410);
	$rational_factorials{9474}=2.5382082601510843498365329718708*(10**2410);
	$rational_factorials{9473}=1.2789491855029627311008671106812*(10**2410);
	$rational_factorials{9472}=6.4444210620737959423486878517557*(10**2409);
	$rational_factorials{9471}=3.2472753040633473688704316661848*(10**2409);
	$rational_factorials{9470}=1.6362847924389660420790503223357*(10**2409);
	$rational_factorials{9469}=8.245239252051498782451027346942*(10**2408);
	$rational_factorials{9468}=4.1548200060341639707674999923119*(10**2408);
	$rational_factorials{9467}=2.0936580473319414488851925753404*(10**2408);
	$rational_factorials{9466}=1.0550277245520667934535949042175*(10**2408);
	$rational_factorials{9465}=5.3165093201230640213376686407904*(10**2407);
	$rational_factorials{9464}=2.6791305258086176375728657081178*(10**2407);
	$rational_factorials{9463}=1.3500994252116148327888389218634*(10**2407);
	$rational_factorials{9462}=6.8036539928988555134593410597083*(10**2406);
	$rational_factorials{9461}=3.428650938721726711931614049398*(10**2406);
	$rational_factorials{9460}=1.7278614492491721669261355040504*(10**2406);
	$rational_factorials{9459}=8.7076135305222291503337494423297*(10**2405);
	$rational_factorials{9458}=4.3882763054860202479589142293113*(10**2405);
	$rational_factorials{9457}=2.2115327425075963334585323495727*(10**2405);
	$rational_factorials{9456}=1.1145443952588916051696544519517*(10**2405);
	$rational_factorials{9455}=5.6170198839123761451005479564611*(10**2404);
	$rational_factorials{9454}=2.8308648835678546466323602156782*(10**2404);
	$rational_factorials{9453}=1.4267139651396119970293130316637*(10**2404);
	$rational_factorials{9452}=7.1905030573862349539836620795903*(10**2403);
	$rational_factorials{9451}=3.6239836578815418158034182955269*(10**2403);
	$rational_factorials{9450}=1.8264920182337972166238218858884*(10**2403);
	$rational_factorials{9449}=9.2056385775686955812810544902523*(10**2402);
	$rational_factorials{9448}=4.6397507987798903023460712934143*(10**2402);
	$rational_factorials{9447}=2.3385140557339498080348232521652*(10**2402);
	$rational_factorials{9446}=1.1786637005698938294941354187307*(10**2402);
	$rational_factorials{9445}=5.9407931083155749815976181453845*(10**2401);
	$rational_factorials{9444}=2.9943567628177011282339329550224*(10**2401);
	$rational_factorials{9443}=1.5092710939803363979999079992211*(10**2401);
	$rational_factorials{9442}=7.6073879151356696508502561146744*(10**2400);
	$rational_factorials{9441}=3.8344975747344638829789633853845*(10**2400);
	$rational_factorials{9440}=1.9327957864907907054220337416808*(10**2400);
	$rational_factorials{9439}=9.7424474310177749828352783260158*(10**2399);
	$rational_factorials{9438}=4.9108285338483174241596859583132*(10**2399);
	$rational_factorials{9437}=2.4754038909007619435109804722825*(10**2399);
	$rational_factorials{9436}=1.2477913408531588285984918682307*(10**2399);
	$rational_factorials{9435}=6.2898815334204076035972664323817*(10**2398);
	$rational_factorials{9434}=3.1706446027294590514971759371267*(10**2398);
	$rational_factorials{9433}=1.5982961918673476628189219519444*(10**2398);
	$rational_factorials{9432}=8.0569666544542148388585639850396*(10**2397);
	$rational_factorials{9431}=4.0615375222269504109511316443009*(10**2397);
	$rational_factorials{9430}=2.0474531636554986286250357433059*(10**2397);
	$rational_factorials{9429}=1.0321482605167681939649622127361*(10**2397);
	$rational_factorials{9428}=5.2032512543423579404107713056932*(10**2396);
	$rational_factorials{9427}=2.6230834914705541416880157595448*(10**2396);
	$rational_factorials{9426}=1.3223731886955901108504576814653*(10**2396);
	$rational_factorials{9425}=6.6665411059039826217247126999276*(10**2395);
	$rational_factorials{9424}=3.360869835413884939047250304353*(10**2395);
	$rational_factorials{9423}=1.694366788791845290807719656466*(10**2395);
	$rational_factorials{9422}=8.5421614232975136120213782708223*(10**2394);
	$rational_factorials{9421}=4.3065820403212283012948061120781*(10**2394);
	$rational_factorials{9420}=2.1712122626251311014051280416818*(10**2394);
	$rational_factorials{9419}=1.0946529435961058372732656832496*(10**2394);
	$rational_factorials{9418}=5.518934296078020725934208003493*(10**2393);
	$rational_factorials{9417}=2.7825220021964083395438800886229*(10**2393);
	$rational_factorials{9416}=1.4028996273027690545835536616437*(10**2393);
	$rational_factorials{9415}=7.0732531627628462829970426524431*(10**2392);
	$rational_factorials{9414}=3.5662880256938507417733980309349*(10**2392);
	$rational_factorials{9413}=1.7981182094787703393905546603693*(10**2392);
	$rational_factorials{9412}=9.0661870338542916705809576213355*(10**2391);
	$rational_factorials{9411}=4.571257871055332025575635401845*(10**2391);
	$rational_factorials{9410}=2.3048962448249799377973758404265*(10**2391);
	$rational_factorials{9409}=1.1621753302857053161410613475418*(10**2391);
	$rational_factorials{9408}=5.8599854492227869249673051640401*(10**2390);
	$rational_factorials{9407}=2.9547860276058281188742487932706*(10**2390);
	$rational_factorials{9406}=1.4899103943317428362187273381942*(10**2390);
	$rational_factorials{9405}=7.5127489779743454944206507195359*(10**2389);
	$rational_factorials{9404}=3.7882813104884754002266815709952*(10**2389);
	$rational_factorials{9403}=1.9102498772748011679491709979489*(10**2389);
	$rational_factorials{9402}=9.6325829088974624634306817056264*(10**2388);
	$rational_factorials{9401}=4.8573561481833301727506486046594*(10**2388);
	$rational_factorials{9400}=2.4494115247874388286900912225574*(10**2388);
	no bignum;
	}