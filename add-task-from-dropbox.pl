#!/usr/bin/env perl
use strict;
use warnings;
binmode STDOUT => ':utf8';

use Encode;
use File::Basename;
use Sys::Syslog ':standard';

my $DROPBOX_WATCH_DIR = "$ENV{HOME}/Dropbox/IFTTT/Email/task";
chomp(my $TASK = `which task`);

sub info_log (@) { syslog 'info', @_ }

sub die_with_log (@) {
    my ($format, @args) = @_;
    syslog 'warning', $format, @args;
    closelog;
    die sprintf($format, @args);
}

sub task_file () {
    my ($filename) = <> =~ /^\S+\s+\S+\s+(.*)$/;
    "$DROPBOX_WATCH_DIR/$filename";
}

sub project ($) {
    my ($file) = @_;
    if (basename($file) =~ /^task_(\w+)/) {
        $1;
    } else {
        info_log 'invalid task filename: %s', $file;
        exit 1;
    }
}

sub task_content ($) {
    my ($file) = @_;
    open my $fh, '<', $file or die_with_log 'cannot open file: %s', $file;
    chomp(my $content = <$fh>);
    decode utf8 => $content;
}

sub execute (@) {
    my (@args) = @_;
    system(@args) == 0 or die_with_log 'execution failed: %s', join ' ', @args;
}

sub main () {
    my $file = task_file;
    die_with_log 'task file not found: %s', $file unless -f $file;
    die_with_log 'task executable not found' unless $TASK;

    openlog __FILE__, 'pid', 'user';

    my $project = project $file;
    my $content = task_content $file;

    info_log 'project:%s;content:%s', $project, $content;

    execute $TASK, 'add', "pro:$project", $content;
    execute $TASK, 'sync';
    unlink $file;

    closelog;
}

main if __FILE__ eq $0;
