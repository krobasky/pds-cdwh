#!/usr/bin/perl
use warnings;
use strict;
use 5.010;

use CMDUtil::lib::CMDUtil;

##################
# Set-up
##################
# read-in the default values from config.json

my $root="/home/krobasky";
my $outroot="${root}/data.out";

use Getopt::Long;
my $encoding="ICD10";
my $drugType="DOAC";
my $aeType="bleeding";

my $patDimFilename="/data/CSV/GONZ_${drugType}/patient_dimension.csv";

####xxxx finish this
my $help=0;
my $verbose=0;
GetOptions ("encoding=s"   => \$encoding,
	    "drugType=s"   => \$drugType,
	    "aeType=s"     => \$aeType,
	    "inputFile=s"  => \$patDimFilename,
            "help"         => \$help,
            "verbose"      => \$verbose)
    or die("Error in command line arguments\n");
if($help){
    die($usage);
}

my $pidAEFilename = "${outroot}/${drugType}/${encoding}/${aeType}.pid";
my $pidNOTAEFilename = "${outroot}/${drugType}/${encoding}/NOT${aeType}.pid";

if($verbose) {    print "Verbose ON\n";}

my $fh;

# xxx maybe better just send to STDOUT?
#my $patVarsFilename = "${outroot}/${drugType}/${encoding}/${aeType}.patvars";
#if($verbose) {    print "outroot,drug,code,aetpye=$outroot,$drugType,$encoding,$aeType\n";}
#open(PATVARS,">",$patVarsFilename) or die ("Can't open $patVarsFilename");


open(AEPIDS,"<",$pidAEFilename) or die ("Can't open $pidAEFilename");
if($verbose){print "reading $pidAEFilename\n";}
chomp(my @aePids=<AEPIDS>);
if($verbose){print "got ".($#aePids+1)." pids\n";}

open(NOTAEPIDS,"<",$pidNOTAEFilename) or die ("Can't open $pidNOTAEFilename");
chomp(my @NOTaePids=<NOTAEPIDS>);

if($patDimFilename eq "-") {
    $fh = *STDIN;
    if($verbose) {print STDERR "reading from STDIN\n";}
} else {
    open(my $fh,"<","$patDimFilename") or die ("Can't open input file $patDimFilename");
    if($verbose) {print STDERR "reading from $patDimFilename\n";}
}


my $currentYear = 2019;
my $header=<$fh>;
#print "pid\tage\tyearsDeceased\tsex\traceCode\tethnicityCode\tmaritalStatusCode\treligionCode\tzipCode\tstateCityZip_path\n";
while(<$fh>){

    my ($pid, $vitalsCode, $birthDate, $deathDate, $sex, $languageCode, $raceCode, $ethnicityCode, $maritalStatusCode, $religionCode, 
	$zipCode, $stateCityZip_path, $primeInsClsCd, $primeInsPayerCode, $steDeatDate, $steDeatWms, $updateDate, 
	$downloadDate, $importDate, $sourceSystmeCode, $uploadId, $deathDt) = $_ =~ m/("[^"]+"|[^,]+)(?:,\s*)?/g;

    my $AEFlag=0;
    if($pid ~~ @aePids) { $AEFlag=1; }
    if($pid ~~ @NOTaePids) { 
	if($AEFlag == 1) { die("Error: patient was found in adverse event AND controls list: \npid=$pid\n$pidAEFilename\n$pidNOTAEFilename");}
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
	    $yearsDeceased = $currentYear - $year;
	}
	my($birthDay, @scrap)=split(" ", $birthDate);
	my ($year, $month, $day)=split("/", $birthDay);
	my $age = $currentYear - $year - $yearsDeceased;
	
	print "$pid\t$age\t$yearsDeceased\t$sex\t$raceCode\t$ethnicityCode\t$maritalStatusCode\t$religionCode\t$zipCode\t$stateCityZip_path\t$AEFlag\n";
    } else {
	if($verbose){
	    print("[$pid:SKIP] Not in adverse or controls\n");
	}
    }

}


######################### Documentation ######################### 

__END__

=head1 NAME

  xlate-ae-patvars.pl - creates table of clinical patient variables tagged with whether they encountered an adverse event (1) or not (2) during the study period.

=head1 SYNOPSIS

 ./xlate-ae-patvars.pl [--encoding <ICD10|ICD9>] [--aeType <ae-type>] [--drugType <DOAC|GENT>] [--inputFile <dx-filename>] [--help] [--verbose] 

=head1 DESCRIPTION

B<xlate-ae-patvars.pl>  data will be output to STDOUT
   under $root/<drugType>/<encoding>
 ex.: 
    ./procCSV/filter-pids.pl -e ICD10 -a bleeding -d DOAC
    awk '{print \$1}' ../out/DOAC/ICD10/bleeding.pid-code |sort -u -g > ../out/DOAC/ICD10/bleeding.pid
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
