package MyApp::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::Lite;
use Digest::MD5 qw/md5_hex/;
use Imager;

any '/' => sub {
    my ($c) = @_;

    my @entries = @{$c->dbh->selectall_arrayref(
        q{select * from entry order by entry_id desc limit 10},
        {Slice => {}}
    )};
    return $c->render(
        "index.tt" => {
            entries => \@entries,
        }
    );
};

get '/' => sub {
    my ($c) = @_;
    return $c->render(
        "index.tt" => {
        }
    );
};

post '/post' => sub {
    my ($c) = @_;
    if(my $body = $c->req->param('body')) {
        $c->dbh->insert(entry => +{
            body => $body,
        });
    }
    return $c->redirect('/');
};

post '/upload' => sub {
    my ($c) = @_;
    my $img = $c->req->upload('image') or die;
    open my $fh, '<', $img->path or die $!;
    my $imgdata = do {
        local $/; <$fh>;
    };
    close $fh;
    die unless $imgdata =~ /^\x89PNG\x0d\x0a\x1a\x0a/; # .png format only.
    my $hash = md5_hex($imgdata);
    my $filename = File::Spec->catfile($c->base_dir, "static/$hash.png");
    unless(-e $filename) {
        open my $fh, '>', $filename or die $!;
        print {$fh} $imgdata or die $!;
        close $fh;
    }
    my $image_url = $c->req->base . "static/$hash.png";
    return $c->redirect($image_url);
};

my $clients = {};
any '/echo' => sub {
    my ($c) = @_;
    my $id = md5_hex(rand().$$.{}.time);
    return $c->websocket(sub{
        my $ws = shift;
        $clients->{$id} = $ws;
        $ws->on_receive_message(sub{
            my ($c, $message) = @_;
            $clients->{$_}->send_message($message) for(keys %$clients);
        });
        $ws->on_eof(sub{
            my ($c) = @_;
            delete $clients->{$id};
        });
        $ws->on_error(sub{
            my ($c) = @_;
            delete $clients->{$id};
        });
    });
};

my $iclients = {};
any '/imgecho' => sub {
    my ($c) = @_;
    my $id = md5_hex(rand().$$.{}.time);
    return $c->websocket(sub{
        my $ws = shift;
        $iclients->{$id} = $ws;
        $ws->on_receive_message(sub{
            my ($c, $message) = @_;
#            my $imager = Imager->new()->read(data => $message);
#            $imager->xsize(200);
#            $imager->write(data => $message);
            $iclients->{$_}->send_message($message) for(keys %$iclients);
        });
        $ws->on_eof(sub{
            my ($c) = @_;
            delete $iclients->{$id};
        });
        $ws->on_error(sub{
            my ($c) = @_;
            delete $iclients->{$id};
        });
    });
};

any '/client' => sub {
    my ($c) = @_;
    return $c->render("client.tt");
};

get '/image/{md5}' => sub {
    my ($c, $args) = @_;
    my $filename = File::Spec->catfile($c->base_dir, "static/$args->{md5}");
    open my $fh, '<', $filename or die $!;
    my $imgdata = do {
        local $/; <$fh>;
    };
    close $fh;
    return $c->render_raw(png => $imgdata);
};

post '/account/logout' => sub {
    my ($c) = @_;
    $c->session->expire();
    return $c->redirect('/');
};

1;
