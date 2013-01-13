#!/usr/bin/perl -Iblib/lib -Iblib/arch -I../blib/lib -I../blib/arch
# 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl invalid.t'

# Test file created outside of h2xs framework.
# Run this like so: `perl invalid.t'
#   Jean-Christophe Petkovich <jcpetkovich@gmail.com>     2013/01/06 19:44:47

#########################

use Test::More tests => 16;
use App::QuestionValidator;
use IO::File;

my $fh = new IO::File 't/invalid.csv', 'r';
my $invalid_data = load_question($fh);

process_row_indexes($invalid_data);

# Tests associated with the rules
ok( ! App::QuestionValidator::is_multiple_choice($invalid_data), "Multiple choice check." );
isnt( App::QuestionValidator::count_answers($invalid_data),   4, "Enforce 4 answers." );
isnt( App::QuestionValidator::count_correct($invalid_data),   1, "Check only 1 correct answer exists." );
isnt( App::QuestionValidator::count_incorrect($invalid_data), 2, "Check at least 2 incorrect exist." );
ok( ! App::QuestionValidator::validate_answer_points($invalid_data), "Enforce point rules." );
ok( ! App::QuestionValidator::non_empty_feedback($invalid_data), "Enforce nonempty feedback.");

# Tests associated with formatting
ok( ! App::QuestionValidator::good_type($invalid_data), "Checking question type.");
ok( ! App::QuestionValidator::good_title($invalid_data), "Checking question title.");
ok( ! App::QuestionValidator::good_option_cols($invalid_data), "Checking option columns.");
ok( ! App::QuestionValidator::good_option_placeholders($invalid_data), "Checking option empty placeholders.");
ok( ! App::QuestionValidator::good_option_tag($invalid_data), "Checking option tags.");
ok( ! App::QuestionValidator::good_question_cols($invalid_data), "Checking question row column numbers.");
ok( ! App::QuestionValidator::good_question_text($invalid_data), "Checking question text format.");
ok( ! App::QuestionValidator::good_feedback_format($invalid_data), "Checking question feedback format.");
ok( ! App::QuestionValidator::good_feedback_text($invalid_data), "Checking question feedback text.");

is( validate($invalid_data), 0, "Invalid csv correctly invalidated." );

done_testing();
