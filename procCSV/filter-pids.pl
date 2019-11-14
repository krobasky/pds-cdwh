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
our $config = "filter-pids"; 

our %opt;
our $dxFilename;
# now read the config file and get the defaults


CMDUtil::getDefaults("./procCSV/config.json", $config);
%opt=%CMDUtil::opt;


$dxFilename = $opt{'baseDx'}.$opt{'drugType'}.$opt{'dxFilename'};

use Getopt::Long qw< :config auto_version bundling no_ignore_case >;
use Pod::Usage qw(pod2usage);

# get any override values from command line, and/or print documentation
GetOptions (
    "e|encoding=s"   => \$opt{'encoding'},
    "a|aeType=s"     => \$opt{'aeType'},
    "d|drugType=s"   => \$opt{'drugType'},
    "i|inputFile=s"  => \$opt{'dxFilename'},
    "b|baseDx=s"     => \$opt{'baseDx'},
    "f|fileDx=s"     => \$opt{'fileDx'},
    "c|codesPath=s"  => \$opt{'codesPath'},
    "s|settingsFile=s" => \$opt{'settingsFilename'},
    "r|dryRun!"       => \$opt{'dryrun'},
    "v|verbose!"     => \$opt{'verbose'}, 
    
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
}

# if the input file isn't explicitly specified, construct it from other options
if( ! defined $opt{'dxFilename'} || $opt{'dxFilename'} eq "") {
    $opt{'dxFilename'}="$opt{'baseDx'}$opt{'drugType'}/$opt{'fileDx'}";
    CMDUtil::info("dfFilename is NOT defined, or else it is defined but it's empty, set using baseDx, drugType, fileDx options: $opt{'dxFilename'}");
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

my $codes="$opt{'codesPath'}/$opt{'aeType'}.$opt{'encoding'}.codes";
open(CODES,"<",$codes) or die("Can't open $codes");
chomp(my @ICDCodes=<CODES>);

my $pidsPath="$opt{'outPath'}/$opt{'drugType'}/$opt{'encoding'}";
if( ! -e $pidsPath) {
    use File::Path qw(make_path);
    make_path($pidsPath) or die("Can't create ${pidsPath}");
} else {
    if( ! -d $pidsPath || ! -W _ ) {	die("Can't write files to $pidsPath"); }
}

my $matchName="${pidsPath}/$opt{'aeType'}.pid-code";
my $notMatchName="${pidsPath}/NOT$opt{'aeType'}.pid-code";

if( -e $matchName)    { CMDUtil::info(" ! $matchName will be overwritten"); } 
else                  { CMDUtil::info("Writing to $matchName");}
if( -e $notMatchName) { CMDUtil::info(" ! $notMatchName will be overwritten"); }
else                  { CMDUtil::info("Writing to $notMatchName"); }

if(! $opt{'dryrun'} ) {
    open(MATCH,">",${matchName}) or die ("Can't open $matchName");
    open(NONMATCH,">",${notMatchName}) or die ("Can't open $notMatchName");
}

# these constants could maybe be in the config:
use constant MAX_LINES => 300000000; # ~ 70GB, for the STDIN case where you can't compute the lines in advance
use constant STEP_SIZE => 1000; # number of lines to read before updating the progress bar
my $fh;
my $count;
if($opt{'dxFilename'} eq "-") {
    $fh = *STDIN;
    $count = MAX_LINES;
    CMDUtil::info("reading from STDIN");
} else {
    open($fh,"<",$opt{'dxFilename'}) or die ("Can't open input file $opt{'dxFilename'}");
    $count = `wc -l < $opt{'dxFilename'}`; die "wc failed: $?" if $?; chomp($count);
    CMDUtil::info("reading from $opt{'dxFilename'}");
}

use Term::ProgressBar;
my $progress = Term::ProgressBar->new($count);
my $lineNum=0;
while( <$fh>) {
    $lineNum++;
    if( ($lineNum % STEP_SIZE) == 0) {
	$progress->update($lineNum);
    }
    if( ! $opt{'dryrun'} ){
	my ($enc, $pid, $code, @scrap) = split(",");
	my $matchFound=0;
	foreach my $i (@ICDCodes) {
	    if($code eq "\"$opt{'encoding'}:".$i."\"") {
		print MATCH "${pid}\t${code}\n";
		$matchFound=1;
	    }
	}
	if($matchFound == 0) {
	    print NONMATCH "${pid}\t${code}\n";
	}
    }
}

$progress->update($count);
CMDUtil::info("-----Done. Next: xlate-ae-patvars.pl -----");



######################### Documentation ######################### 

__END__

=head1 NAME

filter-pids.pl - filters i2b2-sourced 'Observation Fact' diagnosis CSV file into patient numbers with/without the adverse event identified by given ICD codes.

=head1 SYNOPSIS

 ./procCSV/filter-pids.pl [--encoding <ICD10|ICD9>] [--aeType <ae-type>] [--drugType <DOAC|GENT>] [--inputFile <dx-filename>] [--codesPath <codes-path>]  [--fileDx <file-dx> | ([--outPath <out-path>] [--baseDx <base-dx>])]

=head1 DESCRIPTION

B<filter-pids> filters i2b2-sourced 'Observation Fact' diagnosis CSV file into patient numbers with/without the adverse event identified by given ICD codes.

 The input i2b2-sourced CSV will be determined by options -b,-d,-f; e.g.:
   Default <base-dx><drug-type><file-dx> = ${dxFilename}
 Data will be output to <ae-type>.pid-code and NOT<ae-type>.pid-code
   under <outPath>/<drugType>/<encoding>
 ex.: 
  ./procCSV/filter-pids.pl -e ICD10 -a bleeding -d DOAC
 reads codes from $opt{'codesPath'}/bleeding.ICD10.codes
 creates files:
  $opt{'outPath'}/DOAC/ICD10/bleeding.pid-code
  $opt{'outPath'}/DOAC/ICD10/NOTbleeding.pid-code

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

=item B<-b>, B<--baseDx>

Base path in which to find the i2b2-sourced 'Observation Fact diagnosis CSV file
                      [$opt{'baseDx'}]

=item B<-f>, B<--fileDx>

Filename of the i2b2-sourced 'Observation Fact diagnosis CSV file
                      [$opt{'fileDx'}]

=item B<-c>, B<--codesPath>

Path to ICD9/ICD10 codes for the advers event (aeType)
                      [$opt{'codesPath'}]

=item B<-s>, B<--settingsFile>

Path to a json containing the programs default values for all the arguments described here. This file is found in B<./procCSV/config.json> by default.


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
