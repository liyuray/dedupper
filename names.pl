use warnings;
use strict;
use Text::CSV_XS;
use List::MoreUtils qw(all any uniq);
use Data::Dumper;
use warnings NONFATAL => 'all', FATAL => 'uninitialized';

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
    push @{$phoneh{$_}}, $line_num foreach (@phones);
    push @{$emailh{$_}}, $line_num foreach (@emails);
    $iter{$line_num}++;
    $line_hash{$line_num} = {
        names => \@names,
        emails => \@emails,
        phones => \@phones,
        row => $row,
    };

#    print @names,
#        @emails,
#            @phones, values %{$row};
}
$csv->eof or $csv->error_diag ();
close $fh;

my @list;
PHONE:
for my $phone (keys %phoneh) {
    next if all {not defined $iter{$_}} @{$phoneh{$phone}};
    my @entry;
    push @entry, $_ for (grep {defined $iter{$_}} @{$phoneh{$phone}});
    delete $iter{$_} for (grep {defined $iter{$_}} @{$phoneh{$phone}});
  LINE_NUM1:
    for my $line_num (@{$phoneh{$phone}}) {
        next LINE_NUM1 unless defined $iter{$line_num};
        for my $phone_inner (@{$iter{$line_num}{phones}}) {
            push @entry, $iter{$_} for (grep {defined $iter{$_}} @{$phoneh{$phone_inner}});
                delete $iter{$_} for (grep {defined $iter{$_}} @{$phoneh{$phone_inner}});
        }
    }
    push @list, \@entry;
#    for (@entry) {
#        next PHONE if $_->{phones} and $_->{emails};
#    }
#    print $phone, $/, Dumper($phoneh{$phone}, \@entry);
}

EMAIL:
for my $email (keys %emailh) {
    next if all {not defined $iter{$_}} @{$emailh{$email}};
    my @entry;
    my @emails = grep {defined $iter{$_}} @{$emailh{$email}};
    push @entry, $iter{$_} for @emails;
    delete $iter{$_} for @emails;
  LINE_NUM2:
    for my $line_num (@{$emailh{$email}}) {
        next LINE_NUM2 unless defined $iter{$line_num};
        for my $email_inner (@{$iter{$line_num}{emails}}) {
            push @entry, $iter{$_} for (grep {defined $iter{$_}} @{$emailh{$email_inner}});
            delete $iter{$_} for (grep {defined $iter{$_}} @{$emailh{$email_inner}});
        }
    }
    push @list, \@entry;
    #    delete $iter{$_} for (@{$emailh{$email}});

}

for my $entry (@list) {
    my (@phones, @emails, @names);
    push @phones, @{$line_hash{$_}{phones}} for @{$entry};
    push @emails, @{$line_hash{$_}{emails}} for @{$entry};
    push @names, @{$line_hash{$_}{names}} for @{$entry};
    print uniq @names, uniq @emails, uniq @phones;
}

print scalar @list;
#Dumper(\@list);
#print Dumper(\@list);
print Dumper(\%iter);
__END__

