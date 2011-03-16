use warnings;
use strict;
use Text::CSV_XS;
use List::Util qw(min max sum);
use List::MoreUtils qw(all any uniq);
use Data::Dumper;
use Carp;
use utf8;
$SIG{__DIE__}  = sub { Carp::confess(@_) };
$SIG{__WARN__} = sub { Carp::cluck(@_) };
binmode STDOUT, 'utf8';

my @phone_list;
my @name_list;
my @rows;
my $line_num;

my $csv = Text::CSV_XS->new ({ binary => 1, always_quote => 1 })
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
open my $fh, "<:encoding(UTF-16)", "test.csv" or die "test.csv: $!";

my $column_names = $csv->getline($fh);
$csv->column_names (@{$column_names});

#print Dumper($column_names);
#print @{$column_names};

my @email_fields = grep {/E\-mail \d+ \- Value/} @{$column_names};
my @phone_fields = grep {/Phone \d+ \- Value/} @{$column_names};
my @name_fields =  grep {/(?:name|initials)/i} @{$column_names};

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
    my @names =
        grep {
            $_ ne ''
                && $_ !~ /[﹐\?¿‥·'\&¸«½¶¤§¥￥¨¼¾±©®Ä³°À¯²\|´]/
            }
            map {$row->{$_}}
                grep {defined $row->{$_}}
                    @name_fields;

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

# Group entries by emails or phone numbers
my $list_num;
while ( $line_num = [sort {$a <=> $b} keys %iter]->[0]) {
    my @entry;
    my %queue;
    $queue{$line_num}++;
    my $i;
    while ($i = [sort {$a <=> $b} keys %queue]->[0]) {
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
    push @list, [sort {$a <=> $b} @entry];
}

#fill in metadata
my @metaresult;
for my $entry (@list) {
    my (@phones, @emails, @names, @lines);
    @lines = @{$entry};
    push @phones, @{$line_hash{$_}{phones}} for @{$entry};
    push @emails, @{$line_hash{$_}{emails}} for @{$entry};
    push @names, @{$line_hash{$_}{names}} for @{$entry};

    @names = uniq @names;
    @emails = uniq @emails;
    @phones = uniq @phones;

    my $best;
    for (map {$names[$_]}(1..$#names)) {
#        next unless defined $best;
        $names[0] = $_, last if /^\p{Ideographic}\p{Ideographic}\p{Ideographic}$/;
    }

    push @metaresult, {
        lines => \@lines,
        names => \@names,
        emails => \@emails,
        phones => \@phones,
    };
}

# find out max values
my %max;
for my $g (qw(lines names emails phones)) {
    $max{$g} = max ( map {scalar @{$_->{$g}}} @metaresult );
}

# Prepare output
sub format_entry {
    my $entry = shift;
    my $p = 0;
    my @item = ('') x (4+sum values %max);
    for my $g qw(lines names emails phones) {
        my @gg = @{$entry->{$g}};
        @item[$p .. $p+scalar @gg] = (scalar @gg, @gg);
        $p+=$max{$g}+1;
    }
    return \@item;
}

#@metaresult = sort {scalar @{$b->{names}} cmp scalar @{$a->{names}}} @metaresult;
#@metaresult = sort {$a->{names}[0] cmp $b->{names}[0]} @metaresult;

$csv->eol ("\r\n");
open $fh, ">:encoding(UTF16)", "new.csv" or die "new.csv: $!";

# build column names
my @header;
for my $g (qw(line name email phone)) {
    push @header, map {"$g$_"} (0..$max{$g.'s'});
}

$csv->print($fh, \@header);
for my $entry (@metaresult) {
#    next if $item->[38] == 0 and any { /\@compal\.com/ } @{$item};
#    next if all { defined $_ && $_ !~ /^\+886/ } @{$item}[39..39+$max[3]];
#    print @{$item}[39..39+$max[3]];
    $csv->print ($fh, format_entry($entry));
}

close $fh or die "new.csv: $!";

__END__

