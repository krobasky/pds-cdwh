#!/usr/bin/perl
use warnings;
use strict;
use 5.010;

use CMDUtil::lib::CMDUtil;

##################
# Set-up
##################
# read-in the default values from config.json
my $settingsFilename = './procCSV/config.json';
# the json has config for multiple programs, just read params for "filter-pids"
our $config = "xlate-ae-patvars";

our %opt;
our $dimFilename;
# now read the config file and get the defaults

CMDUtil::getDefaults($settingsFilename, $config);
%opt=%CMDUtil::opt;


$dimFilename = $opt{'baseDim'}.$opt{'drugType'}.$opt{'fileDim'};

use Getopt::Long qw< :config auto_version bundling no_ignore_case >;
use Pod::Usage qw(pod2usage);


# get any override values from command line, and/or print documentation
GetOptions ("e|encoding=s"   => \$opt{'encoding'},
	    "a|aeType=s"     => \$opt{'aeType'},
	    "d|drugType=s"   => \$opt{'drugType'},
	    "o|outpath=s"    => \$opt{'outPath'},
	    "i|inputFile=s"  => \$opt{'dimFilename'},
	    "b|baseDim=s"    => \$opt{'baseDim'},
	    "f|fileDim=s"    => \$opt{'fileDim'},
	    "s|settingsFile=s" => \$opt{'settingsFilename'},
	    "y|year=i"       => \$opt{'currentYear'},
	    "r|dryRun!"      => \$opt{'dryrun'},
            "v|verbose"      => \$opt{'verbose'}, 

    # Standard options
	    "usage"        => sub { pod2usage(2) },
	    "help|?"       => sub { pod2usage(1) },
	    "manual"       => sub {pod2usage( -exitstatus => 0, -verbose => 2) },
    )
    or pod2usage(2);
pod2usage(1) if $opt{'help'};
pod2usage(-exitval => 0, -verbose => 2) if $opt{'man'};


# re-read configuration if user specified a differieng json file
if(defined $opt{'settingsFilename'} && $opt{'settingsFilename'} ne "") {
    CMDUtil::info("Reading new defaults from:$opt{'settingsFilename'}");
    getDefaults($opt{'settingsFilename'});
} else {
    $opt{'settingsFilename'} = $settingsFilename;
}

# if the input file isn't explicitly specified, construct it from other options
if( ! defined $opt{'dimFilename'} || $opt{'dimFilename'} eq "") {
    $opt{'dimFilename'}="$opt{'baseDim'}$opt{'drugType'}/$opt{'fileDim'}";
    CMDUtil::info("dimFilename is NOT defined, or else it is defined but it's empty, set using baseDim, drugType, fileDim options: $opt{'dimFilename'}");
}

# Finally, dump out the configuration
%CMDUtil::opt = %opt;
CMDUtil::info("--- SETTINGS: ---"); # only prints if verbose is actually on
use Data::Dumper;
CMDUtil::info( Dumper \%opt) ;

# start the dry run
if( $opt{'dryrun'} ) {
    CMDUtil::info("\n******************************* DRY RUN **********************************");
}

##################
# Parse
##################

my $pidsPath="$opt{'outPath'}/$opt{'drugType'}/$opt{'encoding'}";

# test that the pids files exist and are readable
( -e $pidsPath && -d _ ) or  die("Can't write files to $pidsPath");
my $matchName="${pidsPath}/$opt{'aeType'}.pid-code";
my $notMatchName="${pidsPath}/NOT$opt{'aeType'}.pid-code";
( -e $matchName) or die ("$matchName doesn't exist");
( -e $notMatchName) or die ("$matchName doesn't exist");


my $count;

my @aePids; my @unfilteredNOTaePids;
CMDUtil::info("get pids");

chomp( @aePids =`cut -f 1 ${matchName}|sort -u`); die "awk/sort failed: $?" if $?;
CMDUtil::info("got ".($#aePids+1)." pids (with adverse events): ${matchName}\n");

CMDUtil::info("+ cut -f 1 ${notMatchName}|sort -u");
$count = `wc -l < ${notMatchName}`; die "wc failed: $?" if $?; chomp($count);
CMDUtil::info("line count = $count, this might take a minute, please wait...");
my @NOTaePids;

chomp( @unfilteredNOTaePids =`cut -f 1 ${notMatchName}|sort -u`); die "awk/sort failed: $?" if $?;
CMDUtil::info("got ".($#unfilteredNOTaePids+1)." pids with non-adverse events ${notMatchName}\n");
my %hNOTaePids = map { my $x = $_; $x => (! grep(/^${x}$/, @aePids) ? 1 : 0) }  @unfilteredNOTaePids; 
@NOTaePids = grep { $hNOTaePids{$_} eq '1' } keys %hNOTaePids;


#my @NOTaePids = ();
#foreach my $n (@unfilteredNOTaePids) {
#    my $found = 0; foreach my $a (@aePids) { if ($a eq $n) { $found=1;} }
#    if ( ! $found ) { push @NOTaePids , $n; }
#}
CMDUtil::info("got ".($#NOTaePids+1)." pids that never had an adverse event ${notMatchName}\n");

# my $cmdstr=
# "for i in @NOTaePids; do 
#   p=1 ; 
#   for j in @aePids ; do  
#     if [ $j -eq  $i ] ; then 
#       p=0; 
#     fi ; 
#   done; 
#   if [ $p -eq 1 ] ; then 
#     echo $i ; 
#   fi ;
# done ";
# @NOTaePids = split(" ",`$cmdstr`);


# these constants could maybe be in the config:
use constant MAX_LINES => 300000000; # ~ 70GB, for the STDIN case where you can't compute the lines in advance
use constant STEP_SIZE => 1000; # number of lines to read before updating the progress bar
my $fh;
if($opt{'dimFilename'} eq "-") {
    $fh = *STDIN;
    $count = MAX_LINES;
    CMDUtil::info("reading from STDIN");
} else {
    open($fh,"<",$opt{'dimFilename'}) or die ("Can't open input file $opt{'dimFilename'}");
    $count = `wc -l < $opt{'dimFilename'}`; die "wc failed: $?" if $?; chomp($count);
    CMDUtil::info("reading from $opt{'dimFilename'}");
}





my $currentYear = 2019;
my $header=<$fh>;
#print "pid\tage\tyearsDeceased\tsex\traceCode\tethnicityCode\tmaritalStatusCode\treligionCode\tzipCode\tstateCityZip_path\n";

use Term::ProgressBar;
my $progress = Term::ProgressBar->new($count);
my $lineNum=0;
while( <$fh>) {
    $lineNum++;
    if( ($lineNum % STEP_SIZE) == 0) {
        $progress->update($lineNum);
    }

    if( ! $opt{'dryrun'} ){

	my ($pid, $vitalsCode, $birthDate, $deathDate, $sex, $languageCode, $raceCode, $ethnicityCode, $maritalStatusCode, $religionCode, 
	    $zipCode, $stateCityZip_path, $primeInsClsCd, $primeInsPayerCode, $steDeatDate, $steDeatWms, $updateDate, 
	    $downloadDate, $importDate, $sourceSystmeCode, $uploadId, $deathDt) = $_ =~ m/("[^"]+"|[^,]+)(?:,\s*)?/g;
	
	my $AEFlag=0;
	if($pid ~~ @aePids) { $AEFlag=1; }
	if($pid ~~ @NOTaePids) { 
	    if($AEFlag == 1) { die("Error: patient was found in adverse event AND controls list: \npid=$pid\n$matchName\n$notMatchName");}
	    $AEFlag=2; 
	}
	if($AEFlag){
	    $birthDate =~ s/"//g;
	    $deathDate =~ s/"//g;
	    $sex =~ s/"//g;
	    
	    my $yearsDeceased=0;
	    if($deathDate ne "(null)") {
		my($deathDay, @scrap)=split(" ", $deathDate);
		my($year, $month, $day)=split("/", $deathDay);
		$yearsDeceased = $opt{"currentYear"} - $year;
	    }
	    my($birthDay, @scrap)=split(" ", $birthDate);
	    my ($year, $month, $day)=split("/", $birthDay);
	    my $age = $opt{"currentYear"} - $year - $yearsDeceased;
	    
	    print "$pid\t$age\t$yearsDeceased\t$sex\t$raceCode\t$ethnicityCode\t$maritalStatusCode\t$religionCode\t$zipCode\t$stateCityZip_path\t$AEFlag\n";
	} else {
	    CMDUtil::info("[$pid:SKIP] ! Not in adverse or controls");
	}
    }

}



$progress->update($count);
CMDUtil::info("-----Done. Next: analysis -----");


######################### Documentation ######################### 

__END__

=head1 NAME

  xlate-ae-patvars.pl - creates table of clinical patient variables tagged with whether they encountered an adverse event (1) or not (2) during the study period.

=head1 SYNOPSIS

 ./xlate-ae-patvars.pl [--encoding <ICD10|ICD9>] [--aeType <ae-type>] [--drugType <DOAC|GENT>] [--inputFile <dx-filename>] [--help] [--verbose] 

=head1 DESCRIPTION

B<xlate-ae-patvars.pl>  data will be output to STDOUT

The following is an example pipeline: 

#1.
    ./procCSV/filter-pids.pl -e ICD10 -a bleeding -d DOAC
#2.
    head -100 /data/CSV/GONZ_<drugType>/patient_dimension.csv| ./procCSV/xlate-ae-patvars.pl  -e ICD10 -a bleeding -d DOAC -i - > ../out/DOAC/ICD10/bleeding.patvars

 reads 'ae' pids from <outroot>/<drugType>/<encoding>/<aeType>.pid
 reads 'NOTae' pids from <outroot>/<drugType>/<encoding>/NOT<aeType>.pid
 1 = AE
 2 = control


=head1 OPTIONS

=for pod2usage:
  help message for pod2usage

=over

=item B<-e>, B<--encoding>

Discerns which file to use in data.in/codes/<ae-type>.<encoding>.codes
                      [$opt{'encoding'}]    

=item B<-a>, B<--aeType>

Discerns which file to use in data.in/codes/<ae-type>.<encoding>.codes
                      [$opt{'aeType'}] 

=item B<-d>, B<--drugType>

Discerns which drug type to use (e.g., DOAC or GENT)
                      [$opt{'drugType'}]

=item B<-i>, B<--inputFile>

If '-', reads from STDIN. Overrides -b, -f (below)
                      [${dxFilename}]

=item B<-b>, B<--baseDim>

Base path in which to find the i2b2-sourced 'Patient dimension' CSV file
                      [$opt{'baseDim'}]

=item B<-f>, B<--fileDim>

Filename of the i2b2-sourced 'Patient dimension'  CSV file
                      [$opt{'fileDim'}]

=item B<-s>, B<--settingsFile>

Path to a json containing the programs default values for all the arguments described here. This file is found in B<./procCSV/config.json> by default.


=item B<-y>, B<--year>

Year relative to which the patient age will be calculated.


=item B<-r>, B<--dryrun>

Don't do any heavy lifting, just open files, create paths - don't read the big files, don't over-write anything, just print the 'informative' messages if verbose is on. Messages are prepended with '[D]' in dryrun mode.

=item B<-v>, B<--verbose>

Enable verbose mode

=item B<--man>

Print man page.

=back

=head1 TODO

Add in support for more different drugs
Add ICD cods for other adverse events
Make i2b2 file format configurable

=head1 AUTHOR

Kimberly Robasky E<lt>krobasky@gmail.com<gt>


=head1 BUGS

None known.

=head1 SEE ALSO

xlate-ae-patvars.pl

=head1 COPYRIGHT and LICENSE

MIT License
Copyright (c) 2019 Kimberly Robasky/RENCI, UNC Chapel Hill


=cut
