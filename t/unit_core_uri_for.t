use strict;
use warnings;

use Test::More;
use URI;

use lib 't/lib';
use TestApp;

my $request = Catalyst::Request->new( {
                _log => Catalyst::Log->new,
                base => URI->new('http://127.0.0.1/foo')
              } );
my $dispatcher = TestApp->dispatcher;
my $context = TestApp->new( {
                request => $request,
                namespace => 'yada',
              } );

is(
    Catalyst::uri_for( $context, 'quux', { param1 => 'value1' } )->as_string,
    'http://127.0.0.1/foo/yada/quux?param1=value1',
    'URI for undef action with query params'
);

is (Catalyst::uri_for( $context, '/bar/wibble?' )->as_string,
   'http://127.0.0.1/foo/bar/wibble%3F', 'Question Mark gets encoded'
);

is( Catalyst::uri_for( $context, qw/bar wibble?/, 'with space' )->as_string,
    'http://127.0.0.1/foo/yada/bar/wibble%3F/with%20space', 'Space gets encoded'
);

is(
    Catalyst::uri_for( $context, '/bar', 'with+plus', { 'also' => 'with+plus' })->as_string,
    'http://127.0.0.1/foo/bar/with+plus?also=with%2Bplus',
    'Plus is not encoded'
);

is(
    Catalyst::uri_for( $context, '/bar', 'with space', { 'also with' => 'space here' })->as_string,
    'http://127.0.0.1/foo/bar/with%20space?also+with=space+here',
    'Spaces encoded correctly'
);

is(
    Catalyst::uri_for( $context, '/bar', { param1 => 'value1' }, \'fragment' )->as_string,
    'http://127.0.0.1/foo/bar?param1=value1#fragment',
    'URI for path with fragment and query params 1'
);

is(
    Catalyst::uri_for( 'TestApp', '/quux', { param1 => 'value1' } )->as_string,
    '/quux?param1=value1',
    'URI for quux action with query params, called with only class name'
);

is (Catalyst::uri_for( 'TestApp', '/bar/wibble?' )->as_string,
   '/bar/wibble%3F', 'Question Mark gets encoded, called with only class name'
);

is(
    Catalyst::uri_for( 'TestApp', '/bar', 'with+plus', { 'also' => 'with+plus' })->as_string,
    '/bar/with+plus?also=with%2Bplus',
    'Plus is not encoded, called with only class name'
);

is(
    Catalyst::uri_for( 'TestApp', '/bar', 'with space', { 'also with' => 'space here' })->as_string,
    '/bar/with%20space?also+with=space+here',
    'Spaces encoded correctly, called with only class name'
);

# test with utf-8
is(
    Catalyst::uri_for( $context, 'quux', { param1 => "\x{2620}" } )->as_string,
    'http://127.0.0.1/foo/yada/quux?param1=%E2%98%A0',
    'URI for undef action with query params in unicode'
);
is(
    Catalyst::uri_for( $context, 'quux', { 'param:1' => "foo" } )->as_string,
    'http://127.0.0.1/foo/yada/quux?param%3A1=foo',
    'URI for undef action with query params in unicode'
);

# test with object
is(
    Catalyst::uri_for( $context, 'quux', { param1 => $request->base } )->as_string,
    'http://127.0.0.1/foo/yada/quux?param1=http%3A%2F%2F127.0.0.1%2Ffoo',
    'URI for undef action with query param as object'
  );

{
    $request->base( URI->new('http://127.0.0.1/') );

    $context->namespace('');

    is( Catalyst::uri_for( $context, '/bar/baz' )->as_string,
        'http://127.0.0.1/bar/baz', 'URI with no base or match' );

}

# test with undef -- no warnings should be thrown
{
    my $warnings = 0;
    local $SIG{__WARN__} = sub { $warnings++ };

    Catalyst::uri_for( $context, '/bar/baz', { foo => undef } )->as_string,
    is( $warnings, 0, "no warnings emitted" );
}

# make sure caller's query parameter hash isn't messed up
{
    my $query_params_base = {test => "one two",
                             bar  => ["foo baz", "bar"]};
    my $query_params_test = {test => "one two",
                             bar  => ["foo baz", "bar"]};
    Catalyst::uri_for($context, '/bar/baz', $query_params_test);
    is_deeply($query_params_base, $query_params_test,
              "uri_for() doesn't mess up query parameter hash in the caller");
}


{
    my $path_action = $dispatcher->get_action_by_path(
                       '/action/path/six'
                     );

    # 5.80018 is only encoding the first of the / in the arg.
    is(
        Catalyst::uri_for( $context, $path_action, 'foo/bar/baz' )->as_string,
        'http://127.0.0.1/action/path/six/foo%2Fbar%2Fbaz',
        'Escape all forward slashes in args as %2F'
    );
}

{
    my $index_not_private = $dispatcher->get_action_by_path(
                             '/action/chained/argsorder/index'
                            );

    is(
      Catalyst::uri_for( $context, $index_not_private )->as_string,
      'http://127.0.0.1/argsorder',
      'Return non-DispatchType::Index path for index action with args'
    );
}

{
    package MyStringThing;

    use overload '""' => sub { $_[0]->{string} }, fallback => 1;
}

is(
    Catalyst::uri_for( $context, bless( { string => 'test' }, 'MyStringThing' ) ),
    'http://127.0.0.1/test',
    'overloaded object handled correctly'
);

is(
    Catalyst::uri_for( $context, bless( { string => 'test' }, 'MyStringThing' ), \'fragment' ),
    'http://127.0.0.1/test#fragment',
    'overloaded object handled correctly'
);

done_testing;
