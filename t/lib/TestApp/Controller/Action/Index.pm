package TestApp::Controller::Action::Index;

use strict;
use base 'Catalyst::Controller';

sub index : Private {
    my ( $self, $c ) = @_;
    $c->res->body( 'Action-Index index' );
}

1;
