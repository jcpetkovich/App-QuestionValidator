#!/usr/bin/perl -Iblib/lib -Iblib/arch -I../blib/lib -I../blib/arch
# 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl invalid.t'

# Test file created outside of h2xs framework.
# Run this like so: `perl invalid.t'
#   Jean-Christophe Petkovich <jcpetkovich@gmail.com>     2013/01/06 19:44:47

#########################

use Test::More tests => 14;
use App::QuestionValidator;

my $fh = IO::File->new('t/invalid.csv', 'r');
my $valid_data = load_question($fh);

# Tests associated with the rules
ok( ! App::QuestionValidator::is_multiple_choice($valid_data), "Multiple choice check." );
isnt( App::QuestionValidator::count_answers($valid_data),   4, "Enforce 4 answers." );
isnt( App::QuestionValidator::count_correct($valid_data),   1, "Check only 1 correct answer exists." );
isnt( App::QuestionValidator::count_incorrect($valid_data), 2, "Check at least 2 incorrect exist." );
ok( ! App::QuestionValidator::validate_answer_points($valid_data), "Enforce point rules." );
ok( ! App::QuestionValidator::non_empty_feedback($valid_data), "Enforce nonempty feedback.");

# Tests associated with formatting
ok( ! App::QuestionValidator::good_type($valid_data), "Checking question type.");
ok( ! App::QuestionValidator::good_title($valid_data), "Checking question title.");
ok( ! App::QuestionValidator::good_option_cols($valid_data), "Checking option columns.");
ok( ! App::QuestionValidator::good_option_placeholders($valid_data), "Checking option empty placeholders.");
ok( ! App::QuestionValidator::good_option_tag($valid_data), "Checking option tags.");
ok( ! App::QuestionValidator::good_question_cols($valid_data), "Checking question row column numbers.");
ok( ! App::QuestionValidator::good_question_text($valid_data), "Checking question text format.");

is( validate($valid_data), 0, "Invalid csv correctly invalidated." );

done_testing();
