use strict;
use warnings;
use utf8;
use Test::More;

use MyApp;
use MyApp::Web;
use MyApp::DB::Schema;
use MyApp::Web::ViewFunctions;
use MyApp::Web::Dispatcher;

pass "All modules can load.";

done_testing;
