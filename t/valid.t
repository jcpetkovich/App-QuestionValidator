#!/usr/bin/perl -Iblib/lib -Iblib/arch -I../blib/lib -I../blib/arch
# 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl valid.t'

# Test file created outside of h2xs framework.
# Run this like so: `perl valid.t'
#   Jean-Christophe Petkovich <jcpetkovich@gmail.com>     2013/01/05 05:39:51

#########################

use Test::More qw( no_plan );
BEGIN { use_ok( App::QuestionValidator ); }

is( validate( 'valid.csv' ), "Question OK",
    "Valid csv correctly validated.");
