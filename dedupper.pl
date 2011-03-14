use warnings;
use strict;
use Text::CSV_XS;
use List::MoreUtils qw(all any uniq);
binmode STDOUT, 'utf8';

local $, = ',';
local $\ = $/;

#my @rows;
my @lines;
my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ })
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
open my $fh, "<:encoding(utf8)", "test.csv" or die "test.csv: $!";
$csv->column_names ($csv->getline ($fh));

ROW:
while (my $row = $csv->getline_hr ($fh)) {
    my @email_list;
    my @phone_list;
    my @phone_fields = map {"Phone $_ - Value"} (1..5);
    my @email_fields = map {"E-mail $_ - Value"} (1..4);
    next ROW if all { $row->{$_} !~ /\d/ } @phone_fields
        and all { $row->{$_} !~ /\@/ } @email_fields;
    #    next ROW if any { $row->{$_} =~ /\d/ } @phone_fields; # if any digits in number;
#    print map { $row->{$_} } @phone_fields;

    for (@email_fields) {
        my $item = $row->{$_};
        my @emails = map {lc} split / ::: /, $item;
        push @email_list, grep {$_ =~ /\@/} @emails;
    }
    for (@phone_fields) {
        my $item = $row->{$_};
        my @phones = map {my $t = $_; $t =~ tr/ ()-//d; $t} split / ::: /, $item;
        for (@phones) {
            s/^0(\d)/\+886$1/;
            s/^9/\+8869/;
            s/^886/\+886/;
        }
        push @phone_list, grep {$_ =~ /\d/} @phones;
    }
    print @email_list, @phone_list;
    push @lines, $row;
}

local $, = $/;
#print uniq sort @email_list;

$csv->eof or $csv->error_diag ();
close $fh;

__END__

$csv->eol ("\r\n");
open $fh, ">:encoding(utf8)", "new.csv" or die "new.csv: $!";
$csv->print ($fh, $_) for @rows;
close $fh or die "new.csv: $!";
