use warnings;
use strict;
use Text::CSV_XS;
use List::MoreUtils qw(all any uniq);
binmode STDOUT, 'utf8';

local $, = ',';
local $\ = $/;

my @email_list;
my @phone_list;
my @rows;
my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ })
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
open my $fh, "<:encoding(utf16-le)", "test.csv" or die "test.csv: $!";
$csv->column_names ($csv->getline ($fh));
ROW:
while (my $row = $csv->getline_hr ($fh)) {
    my @phone_fields = map {"Phone $_ - Value"} (1..5);
    next ROW if all { $row->{$_} !~ /\d/ } @phone_fields;
    #    next ROW if any { $row->{$_} =~ /\d/ } @phone_fields; # if any digits in number;
#    print $row->{Name}, map { $row->{$_} } @phone_fields;
#    print $row->{"Address 1 - Formatted"} if defined $row->{"Address 1 - Formatted"}; #, values %{$row};
  ITEM:
    for (@phone_fields) {
        my $item = $row->{$_};
        my @phones = map {my $t = $_; $t =~ tr/ ()-//d; $t} split / ::: /, $item;
        for (@phones) {
            s/^0(\d)/\+886$1/;
            s/^9/\+8869/;
            s/^886/\+886/;
#            s/^02/\+8862/;
        }
        push @phone_list, grep {$_ =~ /\d/} @phones;
    }
}
#print $.;
$csv->eof or $csv->error_diag ();
close $fh;

local $, = $/;
@phone_list = sort @phone_list;
print uniq @phone_list;


__END__

$csv->eol ("\r\n");
open $fh, ">:encoding(utf8)", "new.csv" or die "new.csv: $!";
$csv->print ($fh, $_) for @rows;
close $fh or die "new.csv: $!";
