use warnings;
use strict;
use Text::CSV_XS;
use List::MoreUtils qw(all any uniq);
binmode STDOUT, 'utf8';

local $, = ',';
local $\ = $/;

my @phone_fields = map {"Phone $_ - Value"} (1..5);
my @name_fields = split /\n/, <<'ENDNAME';
Name
Given Name
Additional Name
Family Name
Yomi Name
Given Name Yomi
Additional Name Yomi
Family Name Yomi
Name Prefix
Name Suffix
Initials
Nickname
Short Name
Maiden Name
ENDNAME


my @phone_list;
my @name_list;
my @rows;
my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ })
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
open my $fh, "<:encoding(utf8)", "test.csv" or die "test.csv: $!";
$csv->column_names ($csv->getline ($fh));
ROW:
while (my $row = $csv->getline_hr ($fh)) {
    next ROW if all { not defined $row->{$_} } @name_fields;
    #    next ROW if any { $row->{$_} =~ /\d/ } @phone_fields; # if any digits in number;
#    print $row->{Name}, map { $row->{$_} } @phone_fields;
    #    print $row->{"Address 1 - Formatted"} if defined $row->{"Address 1 - Formatted"}; #, values %{$row};
    print map {defined $row->{$_} and $row->{$_} } @name_fields;
}
#print $.;
$csv->eof or $csv->error_diag ();
close $fh;

__END__

$csv->eol ("\r\n");
open $fh, ">:encoding(utf8)", "new.csv" or die "new.csv: $!";
$csv->print ($fh, $_) for @rows;
close $fh or die "new.csv: $!";
