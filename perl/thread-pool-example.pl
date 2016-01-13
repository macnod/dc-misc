#!/usr/bin/perl

use MooseX::Declare;

class ThreadPoolExample {
    use threads;
    use threads::shared;
    use Thread::Queue;

    use FindBin qw($Bin);
    use lib "$Bin";

    use Function::Parameters;
    use DateTime;
    use Getopt::Long qw/:config bundling/;
    use LWP::UserAgent;
    use Utyls;

    has 'thread_queue' => (
        isa => 'Item',
        is => 'ro',
        lazy => 1,
        builder => '_thread_queue_builder');

    has options => (
        isa => 'HashRef',
        is => 'ro',
        lazy => 1,
        builder => '_options_builder');

    has 'u' => (
        isa => 'Utyls',
        is => 'ro',
        default => sub {Utyls->new},
        handles => +[qw/log_format slurp_array split_n_trim/]);

    has 'ua' => (
        isa => 'LWP::UserAgent',
        is => 'ro',
        lazy => 1,
        builder => '_ua_builder');

    method _thread_queue_builder {
        Thread::Queue->new;
    }

    method _options_builder {
        my $o= +{};
        GetOptions($o, (
            'agent|a=s',             # --agent={string} or -a {string}
            'task|t=s',              # --task={string} or -t {string}
            'data|d=s',              # --data={string} or -d {string}
            'thread-count|c=i',      # --thread-count={integer} or -c {integer}
            'sleep|s=i',             # --sleep={integer} or -s {integer}
            'help|h'));              # --help or -h

        # Defaults for --task and --thread-count
        $o->{task}||= '$self->lprint("Hello $_")';
        $o->{data}||= join(
            ',', qw/Tracy Graydon Donnie Todd Charles Michelle Sandy Gary
                    Herta Don/);
        $o->{'thread-count'}||= 3;
        $o->{sleep}||= 2;
        $o->{agent}||= 'thread-pool-example';
        $o;
    }

    method _ua_builder {
        LWP::UserAgent->new(
            timeout => 10,
            agent => $self->options->{agent});
    }

    method _thread_work (Int $id) {
        while(1) {
            my $data= $self->thread_queue->dequeue;
            last unless defined($data);
            my $task= $self->options->{task};
            $task=~ s/\$_/$data/g;
            eval $task;
            if($@) {
                $self->lprint("Error processing task. $@");
                last;
            }
            sleep $self->options->{sleep};
        }
    }

    method lprint (@messages) {print $self->log_format(@messages)}

    method start_thread_pool {
        $self->lprint("Thread pool starting.");
        my @threads;
        for my $id (1..$self->options->{'thread-count'}) {
            push @threads, threads->create(sub {$self->_thread_work($id)});
        }
        $_->join for @threads;
        $self->lprint("Thread pool stopped.");
    }

    method run {
        if($self->options->{help}) {
            print $self->usage;
            exit;
        }
        $self->thread_queue->enqueue(
            $self->options->{data} =~ /^@/
                ? $self->slurp_array(substr($self->options->{data}, 1))
                : $self->split_n_trim(',', $self->options->{data}));
        $self->thread_queue->end;
        $self->start_thread_pool;
    }

    method usage {
        <<'EOD';
USAGE
    thread-pool-example.pl -t {task} -c {count} -s {seconds}

EXAMPLES
    thread-pool-example.pl

    thread-pool-example.pl -k '$self->lprint("hello \$_")' -t 10 -s 5

OPTIONS
    --agent, -a string
        If this program makes HTTP requests, this option dictates how
        the program will identify itself to the remote server.
        Default is 'thread-pool-example'.

    --task, -t string
        Some Perl code that you want the thread pool to execute.  The
        $_ variable will be replaced with a piece of data from --data.
        Default is '$self->lprint("Hello $_")'.

    --thread-count, -c integer
        How many threads you want in the thread pool. Default is 3.

    --sleep, -s integer
        How long you want each thread to sleep after it completes a
        task, before pulling the next task off the queue.

    --data, -d string
        This is the data that you want the thread pool to process.

        If the string starts with a '@', then the string is treated
        like a filename and the data is read from the associated file,
        one task per line.

        Otherwise, if the string doesn't start with a '@', then the
        data is read from the string itself, and the elements for each
        task must be separated by commas.

    --help, -h
        Show this nice documentation.
EOD
    }
}

ThreadPoolExample->new->run;
