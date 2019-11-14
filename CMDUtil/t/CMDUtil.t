# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl CMDUtil.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('CMDUtil') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Data::Dumper;
use lib::CMDUtil;

our $settingsFilename = 't/config.json';
our $config = "filter-pids"; 
our %opt= %CMDUtil::opt;

ok(CMDUtil::getDefaults($settingsFilename, $config),  "Got config ");
%opt=%CMDUtil::opt;
ok(CMDUtil::info( Dumper \%opt) , "dumped options");

require_ok('lib::CMDUtil');


