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

my $person_cache = {};
my $maker = Data::Maker->new(
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
     name => 'dob',
     class => 'Data::Maker::Field::DateTime', 
     args => {
       start => 1920,
       end => 1994,
     }
   }
 ]
);


get '/person' => sub {
  redirect '/person/';
};

get '/person/count' => sub {
	my $count = {
		active => 0,
		deleted => 0
	};
	for my $key(keys(%{$person_cache})) {
		$person_cache->{$key}->{deleted} ? $count->{deleted}++ : $count->{active}++;
	}
	return $count;
};

get '/person/generate/:count' => sub {
	my $count = params->{count};
	$maker->record_count($count);
	while(my $record = $maker->next_record) {
		my $hash = {
			id => $record->id->value, 
			firstname => $record->firstname->value, 
			lastname => $record->lastname->value, 
			dob => $record->dob->value->mdy('/'), 
		};
		$person_cache->{$hash->{id}} = $hash;
	}
	forward '/person/';
};

get '/person/flush' => sub {
	$person_cache = {};
	redirect '/person/';
};

get '/person/' => sub {
  my @out;
  for my $key(keys(%{$person_cache})) {
    my $person = $person_cache->{$key};
    unless($person->{deleted}) {
      push(@out, $person); 
    }
  }
  return \@out;
};

get '/person/deleted' => sub {
	my @out;
	for my $key(keys(%{$person_cache})) {
		my $person = $person_cache->{$key};
		push(@out, $person) if $person->{deleted};
	}
	return \@out;
};

get '/person/delete/:id' => sub {
  my $id = params->{id};
  $person_cache->{$id}->{deleted} = 1;
  redirect '/person/';
};

get '/person/undelete/:id' => sub {
  my $id = params->{id};
  delete $person_cache->{$id}->{deleted};
  redirect "/person/$id";
};

get '/person/:id' => sub {
  my $id = params->{id};
  my $out_hash;
  if (my $cached = $person_cache->{$id}) {
    if ($cached->{deleted}) {
      return {};
    }
    $out_hash = $cached;
  } else  {
		$maker->record_count(10000000);
    my $record = $maker->next_record;
    my $person_hash = { 
      id => $id, 
      firstname => $record->firstname->value, 
      lastname => $record->lastname->value, 
      dob => $record->dob->value->mdy('/'), 
    };
    $person_cache->{$id} = $person_hash;
    $out_hash = $person_hash;
  } 
  return $out_hash;
};

get '/service/' => sub {
  template 'service/index'
};


1;
