#!/usr/bin/perl 

use strict;
use warnings;

package MyFoo {

use Template::Caribou;

template hello => sub {
    'world';
};
}

package MyBar{

use Moose;

with 'Template::Caribou';

__PACKAGE__->template( hello => sub {
    'world';
} );

}
