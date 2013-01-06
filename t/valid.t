#!/usr/bin/perl -Iblib/lib -Iblib/arch -I../blib/lib -I../blib/arch
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl valid.t'

# Test file created outside of h2xs framework.
# Run this like so: `perl valid.t'
#   Jean-Christophe Petkovich <jcpetkovich@gmail.com>     2013/01/05 05:39:51

#########################

use Test::More qw( no_plan );
BEGIN { use_ok(App::QuestionValidator); }

my $valid_data = load_question('t/valid.csv');

ok( is_multiple_choice($valid_data), "Multiple choice check." );
is( count_answers($valid_data),   4, "Enforce 4 answers." );
is( count_correct($valid_data),   1, "Check only 1 correct answer exists." );
is( count_incorrect($valid_data), 2, "Check at least 2 incorrect exist." );
ok( validate_answer_points($valid_data), "Enforce point rules." );

is( validate($valid_data), "Question OK", "Valid csv correctly validated." );

done_testing();
