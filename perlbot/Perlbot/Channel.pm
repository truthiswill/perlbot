package Perlbot::Channel;

use Perlbot::LogFile;
use strict;

use vars qw($AUTOLOAD %FIELDS);
use fields qw(config name log members perlbot);

sub new {
  my $class = shift;
  my ($name, $config, $perlbot) = @_;
  my $singlelogfile = 0;

  if (lc($config->value(channel => $name => 'singlelogfile')) eq 'yes') {
    $singlelogfile = 1;
  }

  my $self = fields::new($class);

  $self->config = $config;
  $self->name = $name;
  $self->log = new Perlbot::LogFile($config->value(bot => 'logdir'), $name, $singlelogfile);
  $self->members = {};
  $self->perlbot = $perlbot;

  return $self;
}

sub AUTOLOAD : lvalue {
  my $self = shift;
  my $field = $AUTOLOAD;

  $field =~ s/.*:://;

  if(!exists($FIELDS{$field})) {
    return;
  }

  debug("AUTOLOAD:  Got call for field: $field", 15);

  $self->{$field};
}

sub log_write {
    my $self = shift;
    if ($self->is_logging) {
	$self->log->write(@_);
    }
}

sub flags {
    my $self = shift;
    $self->config->value(channel => $self->name => 'flags') = shift if @_;
    return $self->config->value(channel => $self->name => 'flags');
}

sub key {
    my $self = shift;
    $self->config->value(channel => $self->name => 'key') = shift if @_;
    return $self->config->value(channel => $self->name => 'key');
}

sub logging {
    my $self = shift;
    $self->config->value(channel => $self->name => 'logging') = shift if @_;

    # open/close logfile if logging value is being set
    if (@_ and $_[0] eq 'no') {
      $self->log->close;
    }

    return $self->config->value(channel => $self->name => 'logging');
}

sub limit {
    my $self = shift;
    $self->config->value(channel => $self->name => 'limit') = shift if @_;
    return $self->config->value(channel => $self->name => 'limit');
}

sub ops {
    my $self = shift;
    return $self->config->value(channel => $self->name => 'op');
}

sub is_op {
  my $self = shift;
  my $user = shift;

  if ($user and $self->ops and
      (grep {$_ eq $user->name } @{$self->ops})) {
    return 1;
  }

  return 0;
}

sub is_logging {
    my $self = shift;
    return ($self->logging and $self->logging eq 'yes');
}

sub add_member {
  my $self = shift;
  my $nick = shift;

  $self->members->{$nick} = 1;
}

sub remove_member {
  my $self = shift;
  my $nick = shift;

  if (exists($self->members->{$nick})) {
    delete $self->members->{$nick};
  }
}

sub clear_member_list {
  my $self = shift;
  
  $self->members = {};
}

sub is_member {
  my $self = shift;
  my $nick = shift;

  defined($self->members->{$nick}) ? return 1 : return 0;
}

sub add_op {
  my $self = shift;
  my $user = shift;
  
  defined $user or return;
  if (!$self->is_op($user)) {
    if(!defined($self->config->value(channel => $self->name => 'op'))) {
      $self->config->_config->channel->{$self->name}->{'op'} = [];
    }
    
    push @{$self->config->value(channel => $self->name => 'op')}, $user->name;
    
  }
}

sub remove_op {
  my $self = shift;
  my $user = shift;
  my $removed_count = 0;
  
  my $old_ops = $self->config->value(channel => $self->name => 'op');
  $self->config->_config->channel->{$self->name}->{'op'} = [];
  
  if(defined($old_ops)) {
    foreach my $old_op (@{$old_ops}) {
      if($user->name eq $old_op) {
        $removed_count++;
        next;
      }
      
      $self->add_op($self->perlbot->get_user($old_op));
    }
  }

  return 1 if $removed_count;
  return 0;
}

sub join {
    my $self = shift;
    # we used to do something here.  leaving the stub in for now.
}

sub part {
    my $self = shift;

    $self->log->close;
}

1;









