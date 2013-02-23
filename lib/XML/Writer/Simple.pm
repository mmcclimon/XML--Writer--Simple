package XML::Writer::Simple;

use 5.006;
use strict;
use warnings FATAL => 'all';
no warnings qw/uninitialized/;

=head1 NAME

XML::Writer::Simple - Perl extension for writing XML data

=head1 SYNOPSIS

    $xml = XML::Writer::Simple->new();

    # do a simple XML tag with text
    $xml->doTag('tag1', 'here is some text content');

    # a more complicated element, 2nd param is a coderef
    # outputs "<tag2a><tag2b>some text</tag2b></tag2a>"
    $xml->doTag('tag2a', sub {
        $xml->doTag('tag2b', 'some text');
    });

    # with attributes
    # outputs '<tag3 title="A Tag" href="example.com">link text</tag3>'
    $xml->doTag('tag3', {
        title => 'A Tag',
        href => 'example.com',
        content => 'link text',
    });

    # do a tag only if the content is non-empty
    $xml->doTagIf('tag3', 'some text')    # outputs <tag2>some text</tag2>
    $xml->doTagIf('tag3', '');            # will not write anything

=head1 DESCRIPTION

This is a convenience module for writing XML for the TML canon. Outputs to
file "tmlCanon.xml", which is hardcoded in (for now). Provides several
convenience methods for writing XML, so that the program doesn't have to
deal with the C<XML::Writer> object directly.

=cut

use base qw/Exporter XML::Writer/;
use vars qw/@EXPORT_OK $VERSION/;
$VERSION = '0.01';
# package vars for ref to output file
my $out;

=head1 METHODS

=over 4

=item * C<new>

    XML::Writer::Simple->new(%params);

Creates the object. Acceptable hash keys for %params are the same as those
for L<XML::Writer>. This module assumes everything is UTF-8, so you can
omit that if you like; it will be provided for you.

=cut

sub new {
    my ($class, %params) = @_;
    $params{ENCODING} ||= 'utf-8';

    my $self = $class->SUPER::new(%params);
    $out = &{$self->{GETOUTPUT}};
    $self->xmlDecl('UTF-8') if $params{ENCODING} eq 'utf-8';
    bless $self, $class;
}

# Automatically ends XML and closes file when writer object leaves scope
sub DESTROY {
    my $self = shift;
    $self->end();
    $out->close();
}

=item * C<doTag>

    doTag($tagName, $content)

This is the function that does all the real work. First parameter is always
the tag name, the 2nd varies in a couple of ways:

=over 4

=item * Simple tags

Takes a tag name and a scalar value for the tag content. Outputs empty tag if
no content is provided

    # outputs '<example>some text inside</example>'
    doTag('example', 'some text inside');

    # outputs '<example />'
    doTag('example');

=item * Nested tags

If C<$content> is a coderef, this will start the tag, execute the coderef,
then close the tag. This allows you to write arbitrarily deep/complex tag 
structures.

    # outputs '<example1><exA>Text 1</exA><exB>Text 2</exB></example1>'
    doTag('example1', sub {
        doTag('exA', 'Text 1');
        doTag('exB', 'Text 2');
    });

    # outputs '<example2><a>100</a><b>101</b><c>102</c></example2>'
    doTag('example2', sub {
        for (my $tag = 'a', my $num = 100; $num < 103; $tag++, $num++) {
            doTag($tag, $num);
        }
    });

=item * Tags with attributes

C<$content> may also be a hashref, with valid keys C<attr> and C<content>.
C<attr> must be an array ref of key/value pairs, and C<content> may be either
a scalar used as the content of that element, or a coderef (as above).

    # outputs "<example3 id='ex3'>text z</example3>"
    doTag('example3', {
        attr => [id => 'ex3', content => 'text z'],
    });

    # outputs '<example4 id="ex4"><exZ>more text</exZ></example4>'
    doTag('example4', { 
        attr => [id => 'ex4'],
        content => sub {
            doTag('exZ', 'more text');
        }
    });

=back

=cut

sub doTag {
    my $self = shift;
	my ($tagName, $content) = @_;
	my @attr;
	if (ref $content eq 'HASH') {
		@attr = @{$content->{attr}};
		$content = $content->{content};
	}

	if (ref $content eq 'CODE') {
	   $self->startTag($tagName, @attr);
	   $content->();
	   $self->endTag($tagName);
	} else {
	   # deal with empty tags appropriately
	   if ($content) {
		  $self->dataElement($tagName, $content, @attr);
	   } else {
		  $self->emptyTag($tagName, @attr);
	   }
	}

}

=item * C<doTagIf>

Another convenience method, only outputs tag if $content evaluates to true.
Exactly the same as calling:
    
    doTag($tagName, $content) if ($content);

=cut
sub doTagIf {
	my ($tagName, $content) = @_;
	doTag($tagName, $content) if ($content);
}


42;

__END__

=back

=head1 SEE ALSO

L<XML::Writer>

=head1 AUTHOR

Michael McClimon, C<< <michael at mcclimon.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-writer-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Writer-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Writer::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Writer-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Writer-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Writer-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Writer-Simple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Michael McClimon.

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

