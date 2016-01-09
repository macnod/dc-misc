package RunContainer;
use File::Copy qw/copy/;
use Exporter 'import';
@EXPORT_OK= qw/container_ip update_etc_hosts/;

sub container_ip {
    my $name= shift;
    return unless `docker ps -a | grep $name`;
    my $inspection= `docker inspect $name | grep IPAddress`;
    $inspection =~ /"IPAddress"\s*:\s*"([^"]+)"/ ? $1 : '';
}

sub update_etc_hosts {
    my ($name, @othernames)= @_;
    my $ip= container_ip($name);
    my @etc= map {s/^\s+|\s+$//sg; $_} do {local @ARGV= '/etc/hosts'; <>};
    my @new_etc;
    for my $line (@etc) {
        if($line =~ /(^|[^-])\b$name(\b[^-]|$)/ && $line =~ /^[^#]/) {
            push @new_etc, "# $line";
        }
        else {
            push @new_etc, $line;
        }
    }
    push @new_etc, "$ip\t$name" . (
        @othernames ? (' ' . join(' ', @othernames)) : '');
    copy('/etc/hosts', '/etc/hosts.backup');
    open(my $fh, '>', '/etc/hosts') or die $!;
    print $fh join("\n", @new_etc), "\n";
    close $fh;
    return $ip;
}
