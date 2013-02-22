package MakerService;
use Dancer ':syntax';
use Data::Maker;
use Data::Maker::Field::Person::LastName;
use Data::Maker::Field::Person::FirstName;
use Data::Maker::Field::DateTime;
use Data::Maker::Field::Code;
use Data::Dumper;
use Data::GUID;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

my $news_cache = {};
my $news_maker = Data::Maker->new(
 record_count => 10000000,
 fields => [
   {
     name => 'id',
     class => 'Data::Maker::Field::Code',
		 args => {
		   code => sub {
			   return Data::GUID->new->as_string;
       }
     }
   },
   {
     name => 'lastname',
     class => 'Data::Maker::Field::Person::LastName',
   },
   {
     name => 'firstname',
     class => 'Data::Maker::Field::Person::FirstName',
   },
   {
     name => 'ssn',
     class => 'Data::Maker::Field::Format',
		 args => {
		   format => '\d\d\d-\d\d-\d\d\d\d'
     }
   },
   {
     name => 'dob',
     class => 'Data::Maker::Field::DateTime', 
     args => {
       start => 1920,
       end => 1994,
     }
   }
 ]
);


my $person_cache = {};
my $person_maker = Data::Maker->new(
 record_count => 10000000,
 fields => [
   {
     name => 'id',
     class => 'Data::Maker::Field::Code',
		 args => {
		   code => sub {
			   return Data::GUID->new->as_string;
       }
     }
   },
   {
     name => 'lastname',
     class => 'Data::Maker::Field::Person::LastName',
   },
   {
     name => 'firstname',
     class => 'Data::Maker::Field::Person::FirstName',
   },
   {
     name => 'ssn',
     class => 'Data::Maker::Field::Format',
		 args => {
		   format => '\d\d\d-\d\d-\d\d\d\d'
     }
   },
   {
     name => 'dob',
     class => 'Data::Maker::Field::DateTime', 
     args => {
       start => 1920,
       end => 1994,
     }
   }
 ]
);

my $maker_index = {
	person => $person_maker,
	news => $news_maker,
};
my $cache_index = {
	person => $person_cache,
	news => $news_cache,
};

get qr{/(\w+)} => sub {
	my ($noun) = splat;
	warn "here I am running /$noun\n";
  redirect "/$noun/";
};

get qr{/(\w+)/count} => sub {
	my ($noun) = splat;
	my $count = {
		active => 0,
		deleted => 0
	};
	my $cache = $cache_index->{$noun};
	for my $key(keys(%{$cache})) {
		$cache->{$key}->{deleted} ? $count->{deleted}++ : $count->{active}++;
	}
	return $count;
};

get qr{/(\w+)/generate/(\d+)} => sub {
	my ($noun, $count) = splat;
	my $maker = $maker_index->{$noun};
	my $cache = $cache_index->{$noun};
	$maker->record_count($count);
	while(my $record = $maker->next_record) {
		my $hash;
		if ($noun eq 'person') {
			$hash = {
				id => $record->id->value, 
				firstname => $record->firstname->value, 
				lastname => $record->lastname->value, 
				ssn => $record->ssn->value, 
				dob => $record->dob->value->mdy('/'), 
			};

		} elsif ($noun eq 'news') {
			$hash = {
				id => $record->id->value, 
				firstname => $record->firstname->value, 
				lastname => $record->lastname->value, 
				ssn => $record->ssn->value, 
				dob => $record->dob->value->mdy('/'), 
			};

		}
		$cache->{$hash->{id}} = $hash;
	}
	redirect "/$noun/";
};

get qr{/(\w+)/flush} => sub {
	my ($noun) = splat;
	my $cache = $cache_index->{$noun};
	for my $key(keys(%{$cache})) {
		delete $cache->{$key};
	}
	redirect "/$noun/";
};

get qr{/(\w+)/} => sub {
	my ($noun) = splat;
  my @out;
	my $cache = $cache_index->{$noun};
  for my $key(keys(%{$cache})) {
    my $record = $cache->{$key};
    unless($record->{deleted}) {
      push(@out, $record); 
    }
  }
  return { $noun => \@out };
};

get qr{/(\w+)/deleted} => sub {
	my ($noun) = splat;
	my @out;
	my $cache = $cache_index->{$noun};
	for my $key(keys(%{$cache})) {
		my $record = $cache->{$key};
		push(@out, $record) if $record->{deleted};
	}
	return { $noun => \@out };
};

get qr{/(\w+)/delete/(.*)} => sub {
	my ($noun, $id) = splat;
	my $cache = $cache_index->{$noun};
  $cache->{$id}->{deleted} = 1;
  redirect "/$noun/";
};

get qr{/(\w+)/undelete/(.*)} => sub {
	my ($noun, $id) = splat;
	my $cache = $cache_index->{$noun};
  delete $cache->{$id}->{deleted};
  redirect "/$noun/$id";
};

get qr{/(\w+)/(\w+)} => sub {
	my ($noun, $id) = splat;
  my $out_hash;
	my $cache = $cache_index->{$noun};
  if (my $cached = $cache->{$id}) {
    if ($cached->{deleted}) {
      return {};
    }
    $out_hash = $cached;
  } else  {
		my $maker = $maker_index->{$noun};
		$maker->record_count(10000000);
    my $record = $maker->next_record;
		my $hash;
		if ($noun eq 'person') {
    	$hash = { 
	      id => $id, 
	      firstname => $record->firstname->value, 
	      lastname => $record->lastname->value, 
				ssn => $record->ssn->value, 
	      dob => $record->dob->value->mdy('/'), 
	    };
		} elsif ($noun eq 'news') {
    	$hash = { 
	      id => $id, 
	      firstname => $record->firstname->value, 
	      lastname => $record->lastname->value, 
				ssn => $record->ssn->value, 
	      dob => $record->dob->value->mdy('/'), 
	    };
		}
    $cache->{$id} = $hash;
    $out_hash = $hash;
  } 
  return $out_hash;
};

get '/service/' => sub {
  template 'service/index'
};


1;
