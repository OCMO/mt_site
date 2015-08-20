package MTDynamicHandler;
use strict;
use warnings;
use nginx;
use File::Spec;

my %htaccess;

# this list must same as list in conf/nginx_common.conf
my @INDEXES = ( 'index.html', 'index.htm', 'index.php' );

sub handler {
    my $r   = shift;
    my $uri = $r->uri;
    my $fn  = $r->filename;
    my $htaccess;
    my @nodes = File::Spec->splitdir($fn);
NODES: while ( scalar @nodes ) {
        my $file = File::Spec->catfile( @nodes, '.htaccess' );
        if ( my @stat = stat $file ) {
            $htaccess
                = (    $htaccess{$file}
                    && $htaccess{$file}{modtime} == $stat[9] )
                ? $htaccess{$file}
                : parse_htaccess($file);
            $htaccess->{modtime} = $stat[9];
            last NODES;
        }
        pop @nodes;
    }

    if ($htaccess) {
        if ( $htaccess->{mode} eq 'dmtml' ) {
            my $cond   = $htaccess->{cond};
            my $script = $htaccess->{script};
            if ( !-f $fn || -d $fn || $fn =~ /$cond/ ) {
                $r->internal_redirect( $htaccess->{script} );
                return OK;
            }
        }
        elsif ( $htaccess->{mode} eq 'dynamic' ) {
            my $script = $htaccess->{script};
            my @files  = ($fn);
            if ( $fn =~ m{/$} ) {
                push @files, map { $fn . $_ } @INDEXES;
            }
            for my $f (@files) {
                if ( -f $f ) {
                    return DECLINED;
                }
            }
            my ($q) = $fn =~ /^.*(\?.*)?$/;
            $r->internal_redirect( $script . ( $q || '' ) );
            return OK;
        }
    }
    return DECLINED;
}

sub parse_htaccess {
    my ($filename) = @_;
    my $htaccess = {};
    open my $fh, '<', $filename;
    my $mode = 'initial';
    while ( my $line = <$fh> ) {
        if ( $mode eq 'initial' ) {
            if ( $line =~ /DynamicMTML/ ) {
                $htaccess->{mode} = $mode = 'dmtml';
            }
            elsif ( $line =~ /Movable Type generated this part/ ) {
                $htaccess->{mode} = $mode = 'dynamic';
            }
        }
        elsif ( $mode eq 'dmtml' ) {
            if ( $line =~ /RewriteCond %{REQUEST_FILENAME} ([^\s]+) \[NC\]/ )
            {
                $htaccess->{cond} = $1;
            }
            if ( $line =~ /RewriteRule \^ ([^\s]+) \[L\]/ ) {
                $htaccess->{script} = $1;
            }
        }
        else {
            if ( $line =~ /RewriteCond %{REQUEST_FILENAME} ([^\s]+) \[NC\]/ )
            {
                $htaccess->{cond} = $1;
            }
            if ( $line =~ /RewriteRule \S+ (\S+)\$2 \[L,QSA\]/ ) {
                $htaccess->{script} = $1;
            }
        }
    }
    close $fh;
    return $htaccess;
}

1;
__END__
