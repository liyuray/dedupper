use warnings;
use strict;
use Text::CSV_XS;
use List::MoreUtils qw(all any uniq);
binmode STDOUT, 'utf8';

local $, = ',';
local $\ = $/;

my @email_fields = map {"E-mail $_ - Value"} (1..4);
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
open my $fh, "<:encoding(utf16-le)", "test.csv" or die "test.csv: $!";
$csv->column_names ($csv->getline ($fh));
ROW:
while (my $row = $csv->getline_hr ($fh)) {
    next if any { $row->{$_} =~ /\d/ } @phone_fields;
    next if any { $row->{$_} =~ /\@/ } @email_fields;
#    next ROW if all { $row->{$_} !~ /\d/ } @phone_fields
#        and all { $row->{$_} !~ /\@/ } @email_fields;
    my (@emails, @phones);
    for (@email_fields) {
        my $item = $row->{$_};
        push @emails, grep {$_ =~ /\@/} map {lc}
            split / ::: /, $item;
    }
    for (@phone_fields) {
        my $item = $row->{$_};
        my @phones_items = grep {$_ =~ /\d/}
            split / ::: /, $item;
        for (@phones_items) {
            tr/ ()-//d;
            s/^0(\d)/\+886$1/;
            s/^9/\+8869/;
            s/^886/\+886/;
        }
        push @phones, @phones_items;
    }
    my @names = map {$row->{$_}} grep {defined $row->{$_}} @name_fields;
    print @names,
        @emails,
            @phones, values %{$row};
}
#print $.;
$csv->eof or $csv->error_diag ();
close $fh;

__END__

$csv->eol ("\r\n");
open $fh, ">:encoding(utf8)", "new.csv" or die "new.csv: $!";
$csv->print ($fh, $_) for @rows;
close $fh or die "new.csv: $!";
