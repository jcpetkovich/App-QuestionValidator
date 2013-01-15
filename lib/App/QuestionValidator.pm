
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

If you are looking for a commandline interface
 you should look at
B<question-validator>.

This module supplies the necessary functions for validating learn
style multiple choice questions.

    use App::QuestionValidator;

    my $fh = IO::File->new('question.csv' 'r')
    my $fields = load_question($fh);
    if ( "Question OK" eq validate($fields) ) {
        say "Valid!";
    }
    ...

=head1 EXPORT

load_question validate process_row_indexes

=cut

our @EXPORT   = qw( load_question validate process_row_indexes );
our $FILENAME = 'question-validator';

=head1 GLOBALS

Don't touch these unless you know that you need to.

=cut

our @TROUBLE_ROWS;

our $ROW_TAG         = 1;
our $OPTION_VALUE    = 2;
our $QUESTION_TYPE   = 0;
our $TYPE_VALUE      = 2;
our $OPTION_FEEDBACK = 5;
our $PLACEHOLDER     = 4;
our $QUESTION_TEXT   = 2;
our $FEEDBACK_TEXT   = 2;

our ( $TYPE_ROW, $TITLE_ROW, $QUESTION_ROW, $FEEDBACK_ROW );

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

=head2 print_stderr

This will print to stderr 

=cut

=head2 say_stderr

Function that prints gcc style messages to stderr.

=cut

sub say_stderr {
    my ( $type, @text ) = @_;

    for (@TROUBLE_ROWS) {
        say STDERR "$FILENAME:", $_->[0], ":0: $type: ", @text;
    }

}

=head2 say_error

Function that prints gcc style errors to stderr.

=cut

sub say_error {
    my @error_text = @_;

    say_stderr( "error", @error_text );
}

=head2 say_note

Function that prints gcc style notes to stderr.

=cut

sub say_note {
    my @error_text = @_;

    say_stderr( "note", @error_text );
}

=head2 row_index

Searches an array of rows for the row number (or numbers) of the row(s) with the desired tag.

=cut

sub row_index {
    my ( $tag, @array ) = @_;
    grep { $array[$_]->[$ROW_TAG] =~ /\Q$tag\E/i } 0 .. $#array;
}

=head2 load_question

Load csv formatted question into memory.

Takes filename as an argument and returns an array reference to the
rows.

=cut

sub load_question {
    my ($fh) = @_;

    my $csv = Text::CSV->new( { binary => 1, auto_diag => 1 } );

    my $fields = [];

    my $pos;
    while ( my $row = $csv->getline($fh) ) {
        unshift @$row, $fh->input_line_number();
        if ( defined($pos)
            && $row->[$ROW_TAG] =~ /newquestion/i )
        {
            # Go back to before this line in the file stream. Wont
            # work on stdin
            unless ( seek $fh, $pos, 0 ) {
                push @$fields, $row;
            }
            last;
        }
        push @$fields, $row;
        $pos = tell $fh;
    }

    return @$fields == 0 ? undef : $fields;
}

=head2 process_row_indexes

Find the row indexes for the question's various fields.

=cut

sub process_row_indexes {
    my ($fields) = @_;
    ($TYPE_ROW)     = row_index 'NewQuestion',  @$fields;
    ($TITLE_ROW)    = row_index 'Title',        @$fields;
    ($QUESTION_ROW) = row_index 'QuestionText', @$fields;
    ($FEEDBACK_ROW) = row_index 'Feedback',     @$fields;
}

=head2 is_multiple_choice

This function checks to make sure the question is properly marked as
multiple choice.

=cut

sub is_multiple_choice {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    # First row second column indicates the question type.

    my $status = $fields->[$QUESTION_TYPE][$TYPE_VALUE] eq "MC";

    push @TROUBLE_ROWS, $fields->[$QUESTION_TYPE] unless $status;

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

    my $r = count_row_pattern { $_->[$ROW_TAG] eq "Option" } $fields;
    splice @TROUBLE_ROWS, 0, 4;
    return $r;
}

=head2 count_correct

This will count the number of options that are considered completely
correct (worth 100% of the points).

=cut

sub count_correct {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    my $r = count_row_pattern {
        $_->[$ROW_TAG] eq "Option" && $_->[$OPTION_VALUE] == 100;
    }
    $fields;

    shift @TROUBLE_ROWS;
    return $r;
}

=head2 count_incorrect

This will count the number of options that are considered completely
incorrect.

=cut 

sub count_incorrect {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    count_row_pattern { $_->[$ROW_TAG] eq "Option" && $_->[$OPTION_VALUE] == 0 }
    $fields;
}

=head2 validate_answer_points

This will ensure that no more than 2 options have a value of greater
than 50% of the marks.

=cut

sub validate_answer_points {
    my ($fields) = @_;

    @TROUBLE_ROWS = ();

    my $opt_with_points = count_row_pattern {
        $_->[$ROW_TAG] eq "Option" && $_->[$OPTION_VALUE] > 0;
    }
    $fields;

    splice @TROUBLE_ROWS, 0, 2;
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
    my @options = grep { $_->[$ROW_TAG] eq "Option" } @$fields;

    for my $option (@options) {

        my $check = not( $option->[$OPTION_FEEDBACK] || '' ) =~ /^\s*$/;
        $status &&= $check;
        unless ($check) {
            push @TROUBLE_ROWS, $option;
        }
    }

    return $status;
}

=head2 good_tag_and_size

This function checks whether or not a tag and size requirement is met
by a simple learn entry.

=cut

sub good_tag_and_size {
    my ( $ROW_NUM, $tag, $size, $fields ) = @_;

    @TROUBLE_ROWS = ();

    my $status = 1;
    unless ( $status &&= defined($ROW_NUM) ) {
        return $status;
    }
    my $type_row = $fields->[$ROW_NUM];

    # The first row must have $size columns, the first of which must
    # contain the correct tag $tag
    $status = @$type_row - 1 == $size && $type_row->[$ROW_TAG] eq $tag;
    push @TROUBLE_ROWS, $type_row;
    return $status;

}

=head2 good_type

This function makes sure the defined type of the question is in the
proper format.

=cut

sub good_type {
    good_tag_and_size( $TYPE_ROW, "NewQuestion", 3, @_ );
}

=head2 good_title

This function makes sure the defined title of the question is in the
proper format.

=cut

sub good_title {
    good_tag_and_size( $TITLE_ROW, "Title", 3, @_ );
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

    my @options = grep { $_->[$ROW_TAG] eq "Option" } @$fields;

    for my $option (@options) {

        # The first row must have 5 columns, the first of which must
        # contain Option
        my $check = @$option - 1 == 5;
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

    my @options = grep { $_->[$ROW_TAG] eq "Option" } @$fields;

    for my $option (@options) {

        # There should be empty placeholders for learn (for reasons
        # that I cannot fathom).
        my $check = $option->[$PLACEHOLDER] =~ /^\s*$/;
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
    my @options = grep { @$_ - 1 == 5 } @$fields;

    for my $option (@options) {
        unless ( $status &&= $option->[$ROW_TAG] eq "Option" ) {
            push @TROUBLE_ROWS, $option;
        }
    }

    return $status;
}

=head2 good_question_cols

Check that the question text row has the proper number of columns.

=cut

sub good_question_cols {
    good_tag_and_size( $QUESTION_ROW, "QuestionText", 3, @_ );
}

=head2 good_text_block

Checks that a textblock exists in the right place, and that it is
formatted to accomodate learn's oddities.

=cut

sub good_text_block {
    my ( $tag_row, $text_col, $fields ) = @_;

    @TROUBLE_ROWS = ();

    my $status = 1;

    unless ( $status &&= defined($tag_row) ) {
        return $status;
    }
    $status = $fields->[$tag_row][$text_col] =~ /\A\R.*\R\z/ms;
    push @TROUBLE_ROWS, $fields->[$tag_row] unless $status;
    return $status;
}

=head2 good_question_text

Check that the question text has newlines where appropriate to make
multiline input possible.

=cut

sub good_question_text {

    good_text_block( $QUESTION_ROW, $QUESTION_TEXT, @_ );
}

=head2 good_feedback_format

Check that the feedback (if present) is properly formatted.

=cut

sub good_feedback_format {
    good_tag_and_size( $FEEDBACK_ROW, "Feedback", 6, @_ );
}

=head2 good_feedback_text

Check to see if the feedback text is properly formatted (if it exists).

=cut

sub good_feedback_text {
    good_text_block( $FEEDBACK_ROW, $FEEDBACK_TEXT, @_ );
}

=head2 validate

Validate the supplied question.

=cut

sub validate {
    my ($fields) = @_;

    process_row_indexes($fields);

    my $status = 1;

    unless ( is_multiple_choice($fields) ) {
        $status = 0;

        say_error "Question set as something other than MC.";
    }

    unless ( count_answers($fields) == 4 ) {
        $status = 0;

        say_error "Exactly four options are required.";
    }

    unless ( count_correct($fields) == 1 ) {
        $status = 0;

        say_error "Exactly one fully correct answer is required.";
    }

    unless ( count_incorrect($fields) >= 2 ) {
        $status = 0;

        say_error "Between 2 and 3 incorrect answers are required.";
    }

    unless ( validate_answer_points($fields) ) {
        $status = 0;

        say_error
          "Only up to two options may be worth more than or equal to 50.";
    }

    unless ( good_type($fields) ) {
        $status = 0;

        say_error
"The type row should have the tag \"NewQuestion\" and should be of size 3";
    }

    unless ( good_title($fields) ) {
        $status = 0;

        say_error
          "The title row should have the tag \"Title\" and should be of size 3";
    }

    unless ( good_option_cols($fields) ) {
        $status = 0;

        say_error "Each option should have 5 columns.";
    }

    unless ( good_option_placeholders($fields) ) {
        $status = 0;

        say_error
"Each option's fourth column should be empty (see example in manual), it's a placeholder for learn's stuff, don't ask me why they did it this way.";
    }

    unless ( non_empty_feedback($fields) ) {
        $status = 0;

        say_error "Feedback required for every option.";
    }

    unless ( good_option_tag($fields) ) {
        $status = 0;

        say_error "Each option row should start with \"Option\".";
    }

    unless ( good_question_cols($fields) ) {
        $status = 0;

        say_error
"The question row should start with \"QuestionText\" and have 3 columns.";
    }

    unless ( good_question_text($fields) ) {

        say_note
"I suggest putting a newline at the very beginning of your question text, and also at the very end. If you do not put newlines at the beginning and the end of the string, learn will not treat your newlines literally, and will format your question as it sees fit.";
    }

    unless ( good_feedback_format($fields) ) {
        say_error
"Question feedback rows should start with \"Feedback\" and have 6 columns.";
    }

    unless ( good_feedback_text($fields) ) {

        say_note
"I suggest putting a newline at the very beginning of your feedback text, and also at the very end. If you do not put newlines at the beginning and the end of the string, learn will not treat your newlines literally, and will format your feedback as it sees fit.";
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
