use warnings;
use strict;
use Text::CSV_XS;
use List::MoreUtils qw(all any uniq);
use Data::Dumper;
use warnings NONFATAL => 'all', FATAL => 'uninitialized';
use Carp;
$SIG{__DIE__}  = sub { Carp::confess(@_) };
$SIG{__WARN__} = sub { Carp::cluck(@_) };
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
my $line_num;
my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ })
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
open my $fh, "<:encoding(utf16-le)", "test.csv" or die "test.csv: $!";
$csv->column_names ($csv->getline ($fh));
my %phoneh;
my %emailh;
my %line_hash;
my %iter;
ROW:
while (my $row = $csv->getline_hr ($fh)) {
    $line_num++;
#    next if any { $row->{$_} =~ /\d/ } @phone_fields;
    #    next if any { $row->{$_} =~ /\@/ } @email_fields;
    # skip those with no phones and numbers.
    next ROW if all { $row->{$_} !~ /\d/ } @phone_fields
        and all { $row->{$_} !~ /\@/ } @email_fields;
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

    # each phone number can find it's containing line numbers in %phoneh.
    # each line number can find it's contained phone numbers in %line_hash.
    #
    push @{$phoneh{$_}}, $line_num foreach (@phones);
    push @{$emailh{$_}}, $line_num foreach (@emails);
    $iter{$line_num}++;
    $line_hash{$line_num} = {
        names => \@names,
        emails => \@emails,
        phones => \@phones,
        row => $row,
    };
}
$csv->eof or $csv->error_diag ();
close $fh;

my @list;
#print Dumper($phoneh{'+886932064178'});
#for my $phone (('+886932064178', keys %phoneh)) {
my $list_num;
while ( $line_num = [sort {$a <=> $b} keys %iter]->[0]) {
#    print "line_num=$line_num";
    #    delete $iter{$line_num};
    my @entry;
    my %queue;
    $queue{$line_num}++;
    my $i;
    while ($i = [sort {$a <=> $b} keys %queue]->[0]) {
        #    while ([sort {$a <=> $b} keys %iter]->[0]) {
        #        print "i=$i";
        delete $queue{$i};
        push @entry, $i;
        delete $iter{$i};
        my @phones = @{$line_hash{$i}{phones}};
        my @emails = @{$line_hash{$i}{emails}};
        my @queue1;
        push @queue1, grep {defined $iter{$_}} @{$phoneh{$_}} for @phones;
        push @queue1, grep {defined $iter{$_}} @{$emailh{$_}} for @emails;
        @queue1 = uniq sort {$a <=> $b} @queue1;
#        print @queue1;
        $queue{$_}++ for @queue1;
    }
    push @list, \@entry;
}

my @result;
for my $entry (@list) {
    my (@phones, @emails, @names, @lines);
    @lines = @{$entry};
    push @phones, @{$line_hash{$_}{phones}} for @{$entry};
    push @emails, @{$line_hash{$_}{emails}} for @{$entry};
    push @names, @{$line_hash{$_}{names}} for @{$entry};
#    print scalar @lines, @lines, uniq @names, uniq @emails, uniq @phones;
    push @result, [scalar @lines, @lines, uniq @names, uniq @emails, uniq @phones];
}

@result = sort {$b->[0] cmp $a->[0]} @result;
for my $item (@result) {
    print @{$item};
}

print scalar @list;
print Dumper(\@list);
print Dumper(\%iter);
__END__

