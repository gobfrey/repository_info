$c->{repository_info_config} =
{
	'filename' => '_info.html',
	'categories' => [ 'repository','platform','capability','content', 'meta']
};

$c->{repository_info}->{repository} = sub
{
	my ($repo) = @_;

	my $data = {};

	$data->{'contact-email'} = $repo->config('adminemail');

	my $languages = $repo->get_conf('languages');
	$data->{'interface-languages'} = join(',', sort @{$languages});

	foreach my $lang (sort @{$languages})
	{
		$repo->change_lang($lang);
		if ($repo->get_lang->has_phrase('archive_name'))
		{
			$data->{'name_' . $lang} = $repo->phrase('archive_name');
		}
	}	
	
	return $data;
};

$c->{repository_info}->{platform} =
{
        'name' => 'EPrints',
        'version' => EPrints->human_version(),
        'url' => 'http://eprints.org'
};

$c->{repository_info}->{capability} =
{
        'oai-pmh' => 'supported',
	'oai-pmh_version' => '2.0',
        'oai-pmh_url' => sub
        {
                my ($repo) = @_;
                my $url = $repo->config('perl_url') . '/oai2';
                return $url;
        },
        'sword' => 'supported',
	'sword_version' => '2.0',
};


$c->{repository_info}->{content} = sub
{
	my ($repo) = @_;

	my $counts = {};

	my $ds = $repo->dataset('archive');

	return {} unless $ds;

	$ds->map($repo, sub
	{
		my ($repo, $ds, $dataobj, $counts) = @_;

		my $fulltext = 0;
		my $open_fulltext = 0;

		my @docs = $dataobj->get_all_documents(); 		
		if (scalar @docs > 0)
		{
			$fulltext = 1;
			foreach my $doc (@docs)
			{
				$open_fulltext = 1 if $doc->is_public;
			}
		}


		my $keys = [];
		push @{$keys}, 'all_count-metadata';
		push @{$keys}, 'all_count-fulltext' if $fulltext;
		push @{$keys}, 'all_count-open-fulltext' if $open_fulltext;

		my $type = $dataobj->value('type');
		if ($type)
		{
			$type =~ s/_/-/g; #underscores are reserved
			my $key_start = 'type-' . $type . '_count-';
			push @{$keys}, $key_start . 'metadata';
			push @{$keys}, $key_start . 'fulltext' if $fulltext;
			push @{$keys}, $key_start . 'open-fulltext' if $open_fulltext;

		}

		foreach my $k (@{$keys})
		{
			$counts->{$k}++;
		}

	}, $counts);

	return $counts;
};

$c->{repository_info}->{meta} =
{
	'datestamp' => EPrints::Time::iso_date(),
};

