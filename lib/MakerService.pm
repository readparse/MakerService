package MakerService;
use Dancer ':syntax';
use Data::Maker;
use Data::Maker::Field::Person::LastName;
use Data::Maker::Field::Person::FirstName;
use Data::Maker::Field::DateTime;
use Data::Dumper;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

my $person_cache = {};
my $maker = Data::Maker->new(
 record_count => 10000000,
 fields => [
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

get '/person/delete/:id' => sub {
  my $id = params->{id};
  $person_cache->{$id}->{deleted} = 1;
  redirect '/person/';
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
