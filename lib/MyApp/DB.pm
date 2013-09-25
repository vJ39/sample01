package MyApp::DB;
use strict;
use warnings;
use utf8;
use parent qw(Teng Amon2::DBI);

__PACKAGE__->load_plugin('Count');
__PACKAGE__->load_plugin('Replace');
__PACKAGE__->load_plugin('Pager');

1;
