question-validator is a program for validating the format of multiple
choice questions in the learn format. It also gives advice on how to
fix the problems found in the question file.

Rules which must be followed by the questions.
  - All questions must be multiple choice questions with four possible answers.
  - At most one answer must give full points.
  - At least two answers must give zero points.
  - One question may give zero to fifty percent of the points.
  - The question must be compelling, and the right answer should be non-obvious.

# INSTALLATION

To install this module run the following on a cloned repository:
	
	sudo cpan Text::CSV
	perl Makefile.PL
	make
	sudo make install

If you wish to install this module without root permissions I suggest
setting up a local cpan directory using
[local::lib](https://metacpan.org/module/local::lib). Follow its
install instructions and then any module you install using cpan as a
regular user will appear in your home directory under ~/perl5 (by
default).

# DEPENDENCIES 

The package only requires Text::CSV > 1.15 which should be installed
automatically by cpan. 

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
man command:

    man question-validator
    man App::QuestionValidator

Or with the perldoc command:

    perldoc question-validator
    perldoc App::QuestionValidator


# ISSUE TRACKING

Please use github's issue tracker to report issues with the
application. If this is for some reason not possible please email me
with a detailed bug report.

When reporting a bug using either the issue tracker or email please
include the hash ref of the version of this module that you're
using. A hash ref can be obtained using:

    git rev-parse --short HEAD


# LICENSE AND COPYRIGHT

Copyright (C) 2013 Jean-Christophe Petkovich

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

* <http://www.perlfoundation.org/artistic_license_2_0>

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

