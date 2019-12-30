#!/usr/bin/perl

use warnings;
use strict;

binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

use Test::More;
use List::Util qw(sum);

use Unicode::Normalize qw(normalize);

require File::Temp;
use File::Temp ();

my %scripts = ( 'Tamil' => 2, 'Devanagari' => 3, 'Telugu' => 1 );

my @todo_scripts = ( 'Kannada' );

# For each todo-script and done-script, fwd and rev isa. For each
# done-script, for each test-cases 3 (toLatin, NFD fromLatin, NFC
# fromLatin). Plus package, throughLatin

plan tests => 2 * keys(%scripts) + 3 * sum(values(%scripts)) + 2 * @todo_scripts + 2;

use_ok('IndicTranslit');

#IndicTranslit->debug(1);

my ($tlor_fwd, $tlor_rev);

foreach my $script (keys %scripts) {
    $tlor_fwd = IndicTranslit->new($script, 'Latin');
    isa_ok ($tlor_fwd, 'IndicTranslit', "new $script → Latin");

    $tlor_rev = IndicTranslit->new('Latin', $script);
    isa_ok ($tlor_rev, 'IndicTranslit', "new Latin → $script");

    # transliterate return value is backwards

    my ($test);

    for (1 .. $scripts{$script}) {
        ok (
            ! $tlor_fwd->transliterate("< test-cases/$script/$_.$script", "| cmp -s test-cases/$script/$_.Latin -"),
            "$script → Latin: $_"
            );

        open $test, "< test-cases/$script/$_.Latin" or die $!;
        binmode ($test, ':utf8');

        foreach my $normal_form ('NFD', 'NFC') {
            my $tmpfh = new File::Temp();

            binmode($tmpfh, ':utf8');

            normalise ($normal_form, $test, $tmpfh);

            ok (
                ! $tlor_rev->transliterate("< ". $tmpfh->filename, "| cmp -s test-cases/$script/$_.$script -"),
                "$normal_form Latin → $script: $_"
                );

            seek($test, 0, 0);
        }

        close $test;
    }
}

#cmp_ok ($tlor->transliterate('< charsets/ta_latin.txt', '| cmp -s charsets/te_telugu.txt -') >> 8, '==', 1, 'also passed');

TODO: {
    foreach my $script (@todo_scripts) {
        local $TODO = "$script not implemented";

        $tlor_fwd = IndicTranslit->new($script, 'Latin');
        isa_ok ($tlor_fwd, 'IndicTranslit', "new $script->Latin");

        $tlor_rev = IndicTranslit->new('Latin', $script);
        isa_ok ($tlor_rev, 'IndicTranslit', "new Latin->$script");
    }
}

my $tlor = IndicTranslit->new('Tamil', 'Devanagari');
ok (! defined($tlor), 'Tamil->Devanagari needs to go through Latin');

sub normalise {
    local $_;

    my ($normal_form, $infile, $outfile) = @_;

    defined $normal_form or $normal_form = 'NFD';

    defined $infile or die $!;
    defined $outfile or die $!;

    while (<$infile>) {
        print $outfile normalize($normal_form, $_);
    }
}
