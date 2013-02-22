yum -y install perl-devel gcc make 'gcc-c++'
if [ ! -e /usr/bin/cpanm ]
  then wget -O /usr/bin/cpanm http://cpanmin.us
fi
chmod 755 /usr/bin/cpanm
cpanm Moose
cpanm Dancer
cpanm Data::Maker
cpanm JSON
cpanm YAML
cpanm Data::GUID
