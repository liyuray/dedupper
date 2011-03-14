use warnings;
use strict;
use Text::CSV_XS;
use List::MoreUtils qw(all any);
binmode STDOUT, 'utf8';

local $, = ',';
local $\ = $/;

my @rows;
my $csv = Text::CSV_XS->new ({ binary => 1 }) or
    die "Cannot use CSV: ".Text::CSV->error_diag ();
open my $fh, "<:encoding(utf8)", "test.csv" or die "test.csv: $!";
$csv->column_names ($csv->getline ($fh));
ROW:
while (my $row = $csv->getline_hr ($fh)) {
    my @phone_fields = map {"Phone $_ - Value"} (1..5);
#    next ROW if all { $row->{$_} !~ /\d/ } @phone_fields;
    #    next ROW if any { $row->{$_} =~ /\d/ } @phone_fields; # if any digits in number;
#    print map { $row->{$_} } @phone_fields;

    my @email_fields = map {"E-mail $_ - Value"} (1..4);
    next ROW if all { $row->{$_} !~ /\@/ } @email_fields;
    #next ROW if any { $row->{$_} =~ /\d/ } @phone_fields; # if any digits in number;
    print map { $row->{$_} } @email_fields;
}

$csv->eof or $csv->error_diag ();
close $fh;

__END__

$csv->eol ("\r\n");
open $fh, ">:encoding(utf8)", "new.csv" or die "new.csv: $!";
$csv->print ($fh, $_) for @rows;
close $fh or die "new.csv: $!";
