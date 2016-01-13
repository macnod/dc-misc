use MooseX::Declare;
use FindBin qw($Bin);
use lib "$Bin";

class Utyls {
    use Function::Parameters qw/:strict/;
    use Data::Dumper;
    use List::Util qw/first max maxstr min minstr reduce shuffle sum/;
    use DateTime;

    method slurp (Str $filename) {do {local (@ARGV, $/)= $filename; <>}}

    method slurp_array (Str $filename) {
        (map {s/[\r\n]+$//; $_} (do {local @ARGV= $filename; <>}))}

    method slurp_n_thaw (Str $filename) {$self->thaw($self->slurp($filename))}

    method spew (Str $filename, Str $data) {
        open(my $fh, '>', $filename) or die $! . " $filename";
        print $fh $data;
        close $fh;
        $data;
    }

    method freeze (Ref $data) {Dumper($data)}

    method thaw (Str $data) {eval('+' . substr($data, 8))}

    method freeze_n_spew (Str $filename, Ref $data) {
        $self->spew($filename, $self->freeze($data));
        $data;
    }

    method clone ($original) {$self->thaw($self->freeze($original))}

    method merge_hashes (@hashrefs) {
        my $result= +{};
        for my $hashref (@hashrefs) {
            for my $key (keys %$hashref) {
                $result->{$key}= $hashref->{$key}}}
        $result;
    }

    method join_paths (@parts) {
        # Given components of a file path, this method will combine the
        # components to create a file path, inserting or removing '/'
        # characters where necessary.
        my $ds= sum map {defined($_) || 0} @parts;
        unless(@parts > 1 && @parts == $ds) {
            die "You must provide at least 2 strings. You provided " .
            join(", ", map {"'$_'"} @parts) . " => $ds"}
        my @paths;
        push @paths, map {/^(.+)\/?$/; $1} shift @parts;
        push @paths, map {/^\/*(.+)\/?$/; $1} @parts;
        my $path= join('/', grep {defined $_ && $_ ne ''} @paths);
        $path =~ s/([^:])\/\//$1\//g;
        $path
    }

    method filename_only (Str $filename) {
        # Given an absolute filename, this method will return the filename
        # itself, without the path information.
        $filename=~ /([^\/\\]+)$/;
        defined($1) ? $1 : ''
    }

    method path_only (Str $filename) {
        $filename =~ /(.+)\/[^\/]+$/; $1
    }

    method replace_extension (Str $filename, Str $new_extension) {
        my $new_filename= '';
        $new_extension= '' unless defined($new_extension);
        $new_extension= substr($new_extension, 1) if $new_extension =~ /^\./;
        $new_filename= $1 if $filename =~ /^(.*)\.[^. ]+$/;
        if ($new_filename ne '' && $new_extension ne '') {
            $new_filename.= ".$new_extension";
        }
        $new_filename= $filename if $new_filename eq '';
        $new_filename
    }

    method split_n_trim (Str|RegexpRef $separator, Str $string) {
        # Like split, but returns an array in which each element is trimed
        # of beginning and ending whitespace. The new array also excludes
        # empty strings.
        grep {$_ ne ''}
        map {$_=~ s/^\s+|\s+$//sg; $_}
        split $separator, $string
    }

    method log_format (@messages) {
        DateTime->now->datetime() . ' ' . join('', @messages) . "\n";
    }

    method with_retries (
        Int :$tries = 3,
        Int :$sleep = 1.0,
        Int :$sleep_multiplier = 3.0,
        CodeRef :$logger = sub {},
        Str :$description,
        CodeRef :$action)
    {
        my $result;
        while($tries--) {
            $result= $action->();
            last if $result;
            $logger->("FAILED: $description");
            last unless $tries;
            $logger->("Will try again in $sleep seconds");
            sleep $sleep;
            $sleep*= $sleep_multiplier;
        }
        $result;
    }

#
# Usage: $value= $u->pluck($merchant_customer, qw/email address/);
#
# Purpose: Does roughly the same as the following code:
#
#     if(
#         $merchant_customer
#         && $merchant_customer->email
#         && $merchant_customer->email->address
#     ) {
#         $value= $merchant_customer->email->address
#     }
#     else {
#         $value= undef;
#     }
#
# But, in addition to working for objects with methods, the pluck
# function works generally with any nested data structures and
# is able to tell apart methods, hash keys, and array indexes.
#
# Returns: The value at the specified location or undef if the value
# doesn't exist or if the location doesn't exist.
#
# Parameters:
#     * $obj: The object or nested data structure
#     * @path: The path within the object to the location that
#       contains the value you want
#
    method pluck (Item $obj, Item $default, @path) {
        return $default unless defined($obj);
        my ($p, $q);
        eval {
            while(defined($p= shift @path)) {
                if(ref($obj) eq 'HASH' && exists $obj->{$p}) {
                    $obj= $obj->{$p}; next}
                if(
                    ref($obj) eq 'ARRAY'
                    && $p =~ /^[0-9]+$/ && defined $obj->[$p]
                ) {
                    $obj= $obj->[$p]; next}
                if(ref($obj) && ($q= $obj->$p)) {
                    $obj= $q; next}
                $obj= $default;
                last;
            }
        };
        $@ ? (ref($default) eq 'CODE' ? $default->($@) : $default) : $obj;
    }

}
