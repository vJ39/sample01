package MyApp::Web;
use strict;
use warnings;
use utf8;
use parent qw/MyApp Amon2::Web/;
use File::Spec;

# dispatcher
use MyApp::Web::Dispatcher;
sub dispatch {
    return (MyApp::Web::Dispatcher->dispatch($_[0]) or die "response is not generated");
}

# load plugins
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
    'Web::CSRFDefender' => {
        post_only => 1,
    },
    'Web::Raw',
    'Web::WebSocket' => {
        max_payload_size => 10000000,
    },
);

# setup view
use MyApp::Web::View;
{
    my $view = MyApp::Web::View->make_instance(__PACKAGE__);
    sub create_view { $view }
}

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;

        # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
        $res->header( 'X-Content-Type-Options' => 'nosniff' );

        # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
        $res->header( 'X-Frame-Options' => 'DENY' );

        # Cache control.
        $res->header( 'Cache-Control' => 'private' );
    },
);

__PACKAGE__->add_trigger(HTML_FILTER => sub {
    my ($c, $html) = @_;
    $html =~ s/さいきろん/さいくろん/g;
    return $html;
});

__PACKAGE__->add_trigger(
    BEFORE_DISPATCH => sub {
        my ( $c ) = @_;
        # ...
        return;
    },
);

1;
