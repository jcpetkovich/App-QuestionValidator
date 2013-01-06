
package App::QuestionValidator;

use v5.12;
use strict;
use warnings;
use Carp;
use Text::CSV;
use Exporter 'import';

=head1 NAME

App::QuestionValidator - Validates learn-style multiplechoice questions.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

If you are looking for a commandline interface, you should look at
B<question-validator>.

This module supplies the necessary functions for validating learn
style multiple choice questions.

    use App::QuestionValidator;

    my $fields = load_question(IO::File->new('question.csv', 'r'));
    if ( "Question OK" eq validate($fields) ) {
        say "Valid!";
    }
    ...

=head1 EXPORT

load_question validate

=cut

our @EXPORT    = qw( load_question validate );
our @EXPORT_OK = qw( is_multiple_choice count_answers count_correct
  count_incorrect validate_answer_points good_type good_title
  good_option_format good_question_text non_empty_feedback
  good_option_cols good_option_placeholders good_option_tag );

=head1 GLOBALS

Don't touch these unless you know that you need to.

=cut

our @TROUBLE_ROWS;

=head1 SUBROUTINES/METHODS

=head2 row_to_string

Converts a csv row from an array to it's properly formatted string.

Handles multiline pieces of csv rows correctly.

=cut

sub row_to_string {
    my ($row) = @_;
    my $csv = Text::CSV->new( { binary => 1, auto_diag => 1 } );
    $csv->combine(@$row);
    return $csv->string();
}

=head2 dump_trouble_rows

This should print the rows which are causing trouble.

=cut

sub dump_trouble_rows {
    for (@TROUBLE_ROWS) {
        say STDERR "    ", row_to_string($_);
    }
}

=head2 load_question

Load csv formatted question into memory.

Takes filename as an argument and returns an array reference to the
rows.

=cut

sub load_question {
    my ($fh) = @_;

    my $csv = Text::CSV->new( { binary => 1, auto_diag => 1 } );
    my $fields = $csv->getline_all($fh);

    return $fields;
}

=head2 is_multiple_choice

This function checks to make sure the question is properly marked as
multiple choice.

=cut

sub is_multiple_choice {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    # First row second column indicates the question type.

    my $status = $fields->[0][1] eq "MC";

    push @TROUBLE_ROWS, $fields->[0] unless $status;

    return $status;
}

=head2 count_row_pattern

This function uses a test on each row. A count of the number of rows
for which the test evaluates to true is returned. Takes a reference to
an array of rows.

Example:

    count_row_pattern { $_->[0] eq "Option" } $fields;

This would return the number of rows for which the first column
contains "Option".

=cut

sub count_row_pattern (&$) {
    my ( $CODE, $fields ) = @_;

    my $count;
    for $_ (@$fields) {
        if ( $CODE->() ) {
            $count++;
            push @TROUBLE_ROWS, $_;
        }
    }
    return $count;
}

=head2 count_answers

This will count the number of options in the question.

=cut

sub count_answers {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    count_row_pattern { $_->[0] eq "Option" } $fields;
}

=head2 count_correct

This will count the number of options that are considered completely
correct (worth 100% of the points).

=cut

sub count_correct {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    count_row_pattern { $_->[0] eq "Option" && $_->[1] == 100 } $fields;
}

=head2 count_incorrect

This will count the number of options that are considered completely
incorrect.

=cut 

sub count_incorrect {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    count_row_pattern { $_->[0] eq "Option" && $_->[1] == 0 } $fields;
}

=head2 validate_answer_points

This will ensure that no more than 2 options have a value of greater
than 50% of the marks.

=cut

sub validate_answer_points {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    my $opt_with_points =
      count_row_pattern { $_->[0] eq "Option" && $_->[1] > 0 } $fields;

    return $opt_with_points <= 2;
}

=head2 non_empty_feedback

This will ensure that no more than 2 options have a value of greater
than 50% of the marks.

=cut

sub non_empty_feedback {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    my $status = 1;
    my @options = grep { $_->[0] eq "Option" } @$fields;

    for my $option (@options) {

        my $check = not $option->[4] =~ /^\s*$/;
        $status &&= $check;
        unless ($check) {
            push @TROUBLE_ROWS, $option;
        }
    }

    return $status;
}

=head2 good_type

This function makes sure the defined type of the question is in the
proper format.

=cut

sub good_type {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    my $type_row = $fields->[0];

    # The first row must have 3 columns, the first of which must
    # contain NewQuestion
    my $status = @$type_row == 3 && $type_row->[0] eq "NewQuestion";
    push @TROUBLE_ROWS, $type_row;
    return $status;
}

=head2 good_title

This function makes sure the defined title of the question is in the
proper format.

=cut

sub good_title {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    my $title_row = $fields->[1];

    # The first row must have 3 columns, the first of which must
    # contain Title
    my $status = @$title_row == 3 && $title_row->[0] eq "Title";

    push @TROUBLE_ROWS, $title_row;

    return $status;
}

=head2 good_option_cols

This function makes sure the options defined in the supplied question
have the correct number of columns.

=cut

sub good_option_cols {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    # Correct format until proven guilty... er... I mean correct.
    my $status = 1;

    my @options = grep { $_->[0] eq "Option" } @$fields;

    for my $option (@options) {

        # The first row must have 5 columns, the first of which must
        # contain Option
        my $check = @$option == 5;
        $status &&= $check;
        unless ($check) {
            push @TROUBLE_ROWS, $option;
        }
    }

    return $status;
}

=head2 good_option_placeholders

This function makes sure the options defined in the supplied question
have empty placeholders where required by learn.

=cut

sub good_option_placeholders {

    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    # Correct format until proven guilty... er... I mean correct.
    my $status = 1;

    my @options = grep { $_->[0] eq "Option" } @$fields;

    for my $option (@options) {

        # There should be empty placeholders for learn (for reasons
        # that I cannot fathom).
        my $check = $option->[3] =~ /^\s*$/;
        $status &&= $check;
        unless ($check) {
            push @TROUBLE_ROWS, $option;
        }
    }

    return $status

}

=head2 good_option_tag

This function makes sure the options defined in the supplied question
have the correct leading tags.

It will find the rows that look like options (have exactly 5 columns).

=cut

sub good_option_tag {

    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    my $status = 1;

    # Search for things that look like an options but which may not
    # necessarily be labeled as such.
    my @options = grep { @$_ == 5 } @$fields;

    for my $option (@options) {
        unless ( $status &&= $option->[0] eq "Option" ) {
            push @TROUBLE_ROWS, $option;
        }
    }

    return $status;
}

=head2 good_question_cols

Check that the question text row has the proper number of columns.

=cut

sub good_question_cols {
    my ($fields) = @_;
    @TROUBLE_ROWS = ();

    my $status = @{ $fields->[2] } == 3 && $fields->[2][0] eq "QuestionText";
    push @TROUBLE_ROWS, $fields->[2];
    return $status;
}

=head2 good_question_text

Check that the question text has newlines where appropriate to make
multiline input possible.

=cut

sub good_question_text {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    # Check that the question text has a newline at the very beginning
    # and at the very end.

    my $status = $fields->[2][1] =~ /\A\n.*\n\z/ms;
    push @TROUBLE_ROWS, $fields->[2];
    return $status;
}

=head2 validate

Validate the supplied question.

=cut

sub validate {
    my ($fields) = @_;

    my $status = 1;

    unless ( is_multiple_choice($fields) ) {
        $status = 0;

        say STDERR "\nQuestion marked as something "
          . "other than multiple choice. Fix:";
        dump_trouble_rows;
    }

    unless ( count_answers($fields) == 4 ) {
        $status = 0;

        say STDERR
          "\nThere should be 4 answers to your multiple choice question"
          . " (check for mispellings of \"Option\"). Found:\n";
        dump_trouble_rows;
    }

    unless ( count_correct($fields) == 1 ) {
        $status = 0;

        say STDERR
          "\nThere Should be one and only one fully correct answer. Found:\n";
        dump_trouble_rows;

    }

    unless ( count_incorrect($fields) >= 2 ) {
        $status = 0;

        say STDERR
          "\nThere should be between 2 and 3 incorrect answers. Found only:\n";
        dump_trouble_rows;
    }

    unless ( validate_answer_points($fields) ) {
        $status = 0;

        say STDERR "\nThere should be no more than two options worth more "
          . "than 50%. Found:\n";
        dump_trouble_rows;
    }

    unless ( good_type($fields) ) {
        $status = 0;

        say STDERR "\nThe row defining the type of the question should start "
          . "with \"NewQuestion\" and have 3 columns. Found:\n";
        dump_trouble_rows;
    }

    unless ( good_title($fields) ) {
        $status = 0;

        say STDERR "\nThe row defining the title of the question should start "
          . "with \"Title\" and have 3 columns. Found:\n";
        dump_trouble_rows;
    }

    unless ( good_option_cols($fields) ) {
        $status = 0;

        say STDERR "\nEach option should have 5 columns. Fix the following:\n";
        dump_trouble_rows;
    }

    unless ( good_option_placeholders($fields) ) {
        $status = 0;

        say STDERR <<COMMENT;

Each option's fourth column should be empty (see example in manual),
it's a placeholder for learn's stuff, don't ask me why they did it
this way. Offending lines:
COMMENT
        dump_trouble_rows;
    }

    unless ( non_empty_feedback($fields) ) {
        $status = 0;

        say STDERR "\nThere should be non-empty feedback for every option. "
          . "Double check these:\n";
        dump_trouble_rows;
    }

    unless ( good_option_tag($fields) ) {
        $status = 0;

        say STDERR "\nEach option field should start with \"Option\". Found:\n";
        dump_trouble_rows;
    }

    unless ( good_question_cols($fields) ) {
        $status = 0;

        say STDERR "\nThe question row should start with \"QuestionText\" and have 3 columns. Found:\n";
        dump_trouble_rows;
    }

    unless ( good_question_text($fields) ) {
        $status = 0;

        say STDERR <<COMMENT;

OPTIONAL: I suggest putting a newline at the very beginning of your
question text, and also at the very end. If you do not put newlines at
the beginning and the end of the string, learn will not treat your
newlines literally, and will format your question as it sees fit.
COMMENT
        dump_trouble_rows;
    }

    return $status;

    # This should basically be the main function.
}

=head1 AUTHOR

Jean-Christophe Petkovich, <jcpetkovich@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to <jcpetkovich@gmail.com>, I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::QuestionValidator

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Jean-Christophe Petkovich.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of App::QuestionValidator
